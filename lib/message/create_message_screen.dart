import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'chat_screen.dart';

class CreateMessageScreen extends StatefulWidget {
  final int idUser;
  final String accessToken;

  const CreateMessageScreen({super.key, required this.idUser, required this.accessToken});

  @override
  _CreateMessageScreenState createState() => _CreateMessageScreenState();
}

class _CreateMessageScreenState extends State<CreateMessageScreen> {
  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];
  List<dynamic> selectedUsers = [];
  String searchQuery = '';
  bool isAllTabSelected = true;
  bool isLoading = false;
  TextEditingController titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() { isLoading = true; });
    try {
      final patientsResponse = await http.post(
        Uri.parse('https://online.nks.vn/api/nks/patients'),
      );
      final doctorsResponse = await http.post(
        Uri.parse('https://online.nks.vn/api/nks/doctors'),
      );

      List<dynamic> combinedUsers = [];

      if (patientsResponse.statusCode == 200) {
        final data = json.decode(patientsResponse.body);
        if (data['success'] == true && data['data'] != null) {
          combinedUsers.addAll(data['data']);
        }
      }

      if (doctorsResponse.statusCode == 200) {
        final data = json.decode(doctorsResponse.body);
        if (data['success'] == true && data['data'] != null) {
          combinedUsers.addAll(data['data']);
        }
      }

      // Lọc bỏ user trùng id
      combinedUsers.removeWhere((user) =>
      user['id'] != null && user['id'] == widget.idUser
      );

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

  Future<void> createConversation() async {
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng chọn ít nhất 1 thành viên'))
      );
      return;
    }

    // 👉 Nếu chỉ chọn đúng 1 user, kiểm tra xem đã có room chưa
    if (selectedUsers.length == 1) {
      final friendId = selectedUsers[0]['id'].toString();
      try {
        final convRes = await http.post(
          Uri.parse('https://account.nks.vn/api/nks/user/conversations'),
          body: {'access_token': widget.accessToken},
        );
        final data = json.decode(convRes.body);
        if (data['success'] == true && data['data'] != null) {
          final rawConversations = data['data'] as List;
          final existingRoom = rawConversations.firstWhere(
                (room) {
              final mcount = room['mcount'] ?? 0;
              if (mcount != 2) return false;
              final membersStr = room['members']?.toString() ?? '';
              final members = membersStr
                  .replaceAll('{', '')
                  .replaceAll('}', '')
                  .split(',')
                  .map((e) => e.trim())
                  .toList();
              return members.contains(widget.idUser.toString()) && members.contains(friendId);
            },
            orElse: () => null,
          );

          if (existingRoom != null) {
            print('✅ Đã tìm thấy room có sẵn: ${existingRoom['id']}');
            Navigator.of(context).pop(true);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) =>
                    ChatScreen(conversationId: existingRoom['id'].toString(), accessToken: widget.accessToken,)
                ));
            return;
          }
        }
      } catch (e) {
        print('❌ Lỗi kiểm tra room có sẵn: $e');
      }
    }

    // ❗ Nếu không tìm thấy room hoặc chọn nhiều hơn 1 user → tạo mới như cũ
    final memberIds = '{${widget.idUser}},' + selectedUsers.map((e) => '{${e['id']}}').join(',');
    final response = await http.post(
      Uri.parse('https://account.nks.vn/api/nks/user/conversation/store'),
      body: {
        'access_token': widget.accessToken,
        'members': memberIds,
        'title': titleController.text.trim(),
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tạo phòng thành công'))
        );
        Navigator.of(context).pop(true);
        Navigator.push(context,
            MaterialPageRoute(builder: (context) =>
                ChatScreen(conversationId: data['data']['id'].toString(), accessToken: widget.accessToken,)
            ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Tạo phòng thất bại'))
        );
      }
    } else {
      print('❌ HTTP error: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối server'))
      );
    }
  }

  void updateSearch(String query) {
    final newList = allUsers.where((user) {
      final name = user['name']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      searchQuery = query;
      filteredUsers = newList;
    });
  }

  void toggleSelectUser(dynamic user) {
    final exists = selectedUsers.contains(user);
    setState(() {
      if (exists) {
        selectedUsers.remove(user);
      } else {
        selectedUsers.add(user);
      }
    });
  }

  void removeSelectedUser(dynamic user) {
    setState(() {
      selectedUsers.remove(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo tin nhắn'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Hàng avatar đã chọn
            if (selectedUsers.isNotEmpty)
              Container(
                height: 70,
                padding: EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = selectedUsers[index];
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
                            onTap: () => removeSelectedUser(user),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),

            // Ô tìm kiếm
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  prefixIcon: Icon(Icons.search, color: Color(0xff0077bb)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xff0077bb), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xff0077bb), width: 1),
                  ),
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                cursorColor: Color(0xff0077bb),
                onChanged: updateSearch,
              ),
            ),

            // Tabs Tất cả / Đã chọn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAllTabSelected ? Color(0xff0077bb) : Colors.grey[300],
                      foregroundColor: isAllTabSelected ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        isAllTabSelected = true;
                      });
                    },
                    child: Text('Tất cả'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isAllTabSelected ? Color(0xff0077bb) : Colors.grey[300],
                      foregroundColor: !isAllTabSelected ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        isAllTabSelected = false;
                      });
                    },
                    child: Text('Đã chọn'),
                  ),
                ],
              ),
            ),

            Divider(),

            // Danh sách users
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(backgroundColor: Color(0xff0077bb)))
                  : (isAllTabSelected ? filteredUsers : selectedUsers).isEmpty
                  ? Center(child: Text('Không tìm thấy kết quả'))
                  : ListView.builder(
                itemCount: (isAllTabSelected ? filteredUsers : selectedUsers).length,
                itemBuilder: (context, index) {
                  final user = (isAllTabSelected ? filteredUsers : selectedUsers)[index];
                  final name = user['name'] ?? 'Chưa có tên';
                  final avatar = user['avatar']?.toString() ?? '';
                  final isChecked = selectedUsers.contains(user);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      backgroundColor: Color(0xff0077bb),
                      child: avatar.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(name),
                    trailing: Checkbox(
                      value: isChecked,
                      activeColor: Color(0xff0077bb),
                      onChanged: (_) => toggleSelectUser(user),
                    ),
                    onTap: () => toggleSelectUser(user),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Nhập tên phòng (tuỳ chọn)',
                  prefixIcon: Icon(Icons.title, color: Color(0xff0077bb)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xff0077bb), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xff0077bb), width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                cursorColor: Color(0xff0077bb),
              ),
            ),

            // Nút Tạo
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff0077bb),
                  ),
                  onPressed: () {
                    createConversation();
                  },

                  child: Text('Nhắn tin', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}