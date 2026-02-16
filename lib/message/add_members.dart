import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_screen.dart';

class AddMembers extends StatefulWidget {
  final String id;
  final String accessToken;
  final List<dynamic> members;

  const AddMembers({
    super.key,
    required this.accessToken,
    required this.members,
    required this.id,
  });

  @override
  _AddMembersState createState() => _AddMembersState();
}

class _AddMembersState extends State<AddMembers> {
  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];
  List<dynamic> selectedUsers = [];
  bool isAllTabSelected = true;
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() { isLoading = true; });
    try {
      final patientsResponse = await http.post(Uri.parse('https://online.nks.vn/api/nks/patients'));
      final doctorsResponse = await http.post(Uri.parse('https://online.nks.vn/api/nks/doctors'));

      List<dynamic> combinedUsers = [];
      if (patientsResponse.statusCode == 200) {
        final data = json.decode(patientsResponse.body);
        if (data['success'] == true) combinedUsers.addAll(data['data']);
      }
      if (doctorsResponse.statusCode == 200) {
        final data = json.decode(doctorsResponse.body);
        if (data['success'] == true) combinedUsers.addAll(data['data']);
      }

      // Loại bỏ các user đã là members
      final existingIds = widget.members.map((m) => m['id'].toString()).toSet();
      combinedUsers.removeWhere((u) => existingIds.contains(u['id'].toString()));

      setState(() {
        allUsers = combinedUsers;
        filteredUsers = combinedUsers;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Exception: $e');
      setState(() { isLoading = false; });
    }
  }

  void toggleSelectUser(dynamic user) {
    setState(() {
      selectedUsers.contains(user)
          ? selectedUsers.remove(user)
          : selectedUsers.add(user);
    });
  }

  void updateSearch(String query) {
    final list = allUsers.where((user) {
      final name = user['name']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      searchQuery = query;
      filteredUsers = list;
    });
  }

  Future<void> addNewMembersAndGoToChat() async {
    if (selectedUsers.isEmpty) return;

    try {
      // Bước 1: Gọi API lấy danh sách conversations
      final response = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/conversations'),
        body: {'access_token': widget.accessToken},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách phòng')),
        );
        return;
      }

      final data = json.decode(response.body);
      if (data['success'] != true || data['data'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dữ liệu phòng không hợp lệ')),
        );
        return;
      }

      final List<dynamic> allConversations = data['data'];

      // Bước 2: Tạo set targetIds gồm members cũ + mới
      final targetIds = <String>{
        ...widget.members.map((m) => m['id'].toString()),
        ...selectedUsers.map((u) => u['id'].toString()),
      };

      print('🎯 Target IDs: $targetIds');

      // Bước 3: Tìm xem có phòng nào có đúng members không
      for (var conv in allConversations) {
        final membersStr = conv['members'] ?? '';
        final memberIds = membersStr
            .split(',')
            .map((e) => e.toString().replaceAll(RegExp(r'[{} ]'), ''))
            .where((e) => e != null && e.isNotEmpty)
            .toSet();


        print('🔍 Checking conversation ${conv['id']} members: $memberIds');

        if (memberIds.length == targetIds.length && memberIds.containsAll(targetIds)) {
          print('✅ Found existing conversation id: ${conv['id']}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: conv['id'].toString(),
                accessToken: widget.accessToken,
              ),
            ),
          );
          return;
        }
      }

      // Bước 4: Nếu chưa có phòng, gọi API addmember
      final newIds = selectedUsers.map((u) => '{${u['id']}}').join(',');
      print('➕ Adding new members: $newIds');

      final addRes = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/conversation/addmember'),
        body: {
          'id': widget.id,
          'new_members': newIds,
          'access_token': widget.accessToken,
        },
      );

      if (addRes.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể thêm thành viên')),
        );
        return;
      }

      final addData = json.decode(addRes.body);
      if (addData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm thành viên')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm thành viên thất bại')),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showList = isAllTabSelected ? filteredUsers : selectedUsers;

    return Scaffold(
      appBar: AppBar(title: Text('Thêm thành viên')),
      body: Column(
        children: [
          // Hàng avatar: trước là members cũ, sau là selectedUsers
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...widget.members.map((user) {
                  final avatar = user['avatar']?.toString() ?? '';
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      backgroundColor: Colors.blue,
                      child: avatar.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
                ...selectedUsers.map((user) {
                  final avatar = user['avatar']?.toString() ?? '';
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          backgroundColor: Colors.blue,
                          child: avatar.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => toggleSelectUser(user),
                          child: Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          // Tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: Icon(Icons.search, color: Color(0xff0077bb)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: updateSearch,
            ),
          ),

          // Tabs
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => isAllTabSelected = true),
                  child: Text('Tất cả',
                      style: TextStyle(
                          color: isAllTabSelected ? Color(0xff0077bb) : Colors.black)),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => isAllTabSelected = false),
                  child: Text('Đã chọn',
                      style: TextStyle(
                          color: !isAllTabSelected ? Color(0xff0077bb) : Colors.black)),
                ),
              ),
            ],
          ),

          Divider(),

          // Danh sách user
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : showList.isEmpty
                ? Center(child: Text('Không tìm thấy'))
                : ListView.builder(
              itemCount: showList.length,
              itemBuilder: (context, i) {
                final user = showList[i];
                final avatar = user['avatar']?.toString() ?? '';
                final isChecked = selectedUsers.contains(user);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    backgroundColor: Color(0xff0077bb),
                    child: avatar.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
                  ),
                  title: Text(user['name'] ?? 'Không tên'),
                  trailing: Checkbox(
                    value: isChecked,
                    onChanged: (_) => toggleSelectUser(user),
                    activeColor: Color(0xff0077bb),
                  ),

                  onTap: () => toggleSelectUser(user),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xff0077bb)),
                onPressed: addNewMembersAndGoToChat,
                child: Text('Xác nhận', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
