import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ShareScreen extends StatefulWidget {
  final String idMessage;
  final String text;
  final List images;
  final String link;
  final String conversationId;
  final String accessToken;
  final List files;

  const ShareScreen({
    super.key,
    required this.idMessage,
    required this.text,
    required this.images,
    required this.link,
    required this.files,
    required this.conversationId,
    required this.accessToken,
  });

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final TextEditingController _searchController = TextEditingController();
  List roomsAndFriends = [];
  bool isLoading = true;
  String? userId;
  Set<String> selectedIds = {};
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    initUserIdAndLoadData();
  }

  Future<void> initUserIdAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('user_id');
    if (savedId != null) {
      setState(() => userId = savedId.toString());
      await loadData();
    } else {
      print('❌ Không tìm thấy user_id trong SharedPreferences');
      setState(() => isLoading = false);
    }
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      // Lấy conversations
      final convRes = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/conversations'),
        body: {'access_token': widget.accessToken},
      );
      final rawConversations = (json.decode(convRes.body)['data'] ?? []) as List;

      // Lấy doctors và loại bỏ userId
      final docRes = await http.post(
        Uri.parse('https://online.nks.vn/api/nks/doctors'),
        body: {'access_token': widget.accessToken},
      );
      final doctorsRaw = (json.decode(docRes.body)['data'] ?? []) as List;
      final doctors = doctorsRaw.where((d) => d['id'].toString() != userId).toList();

      // Lấy patients và loại bỏ userId
      final patRes = await http.post(
        Uri.parse('https://online.nks.vn/api/nks/patients'),
        body: {'access_token': widget.accessToken},
      );
      final patientsRaw = (json.decode(patRes.body)['data'] ?? []) as List;
      final patients = patientsRaw.where((p) => p['id'].toString() != userId).toList();

      // Gộp friends
      final allFriends = [...doctors, ...patients];
      final friendIds = allFriends.map((f) => f['id'].toString()).toList();

      // Tìm room 2 người: có userId và 1 friend
      final roomsWithFriend = rawConversations.where((room) {
        final mcount = room['mcount'] ?? 0;
        if (mcount == 2) {
          final members = room['members'].toString()
              .replaceAll('{', '')
              .replaceAll('}', '')
              .split(',')
              .map((e) => e.trim())
              .toList();
          return members.contains(userId) && members.any((id) => friendIds.contains(id));
        }
        return false;
      }).toList();

      // Friend đã có room
      final friendsHaveRoomIds = roomsWithFriend.expand((room) {
        final members = room['members'].toString()
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',')
            .map((e) => e.trim());
        return members.where((id) => id != userId && friendIds.contains(id));
      }).toSet();

      // Friend chưa có room
      final friendsWithoutRoom = allFriends
          .where((f) => !friendsHaveRoomIds.contains(f['id'].toString()))
          .toList();

      // Group (>2 người)
      final groupRooms = rawConversations.where((r) => (r['mcount'] ?? 0) > 2).toList();

      setState(() {
        roomsAndFriends = [...groupRooms, ...roomsWithFriend, ...friendsWithoutRoom];
        isLoading = false;
      });

      print('✅ Tải xong: ${roomsAndFriends.length} items (đã loại userId ở doctors & patients)');
    } catch (e) {
      print('❌ Error: $e');
      setState(() => isLoading = false);
    }
  }


  Future<void> shareMessage() async {
    setState(() => isSending = true);  // 🟢 Bắt đầu xoay

    final selected = roomsAndFriends.where((item) => selectedIds.contains(item['id'].toString())).toList();
    print('👉 Chọn share tới: $selectedIds');

    for (var item in selected) {
      String? conversationId;
      final isFriend = item.containsKey('name') && !item.containsKey('members');

      if (isFriend) {
        final friendId = item['id'].toString();
        final members = '{$userId},{$friendId}';

        final createRes = await http.post(
          Uri.parse('https://account.nks.vn/api/nks/user/conversation/store'),
          body: {
            'members': members,
            'access_token': widget.accessToken,
          },
        );
        final data = json.decode(createRes.body);
        if (data['success'] == true && data['data'] != null) {
          conversationId = data['data']['id'].toString();
          print('✅ Đã tạo room mới: $conversationId');
        } else {
          print('❌ Lỗi tạo room: ${data['message']}');
          continue;
        }
      } else {
        conversationId = item['id'].toString();
      }

      final shareRes = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/conversation/share'),
        body: {
          'id': conversationId,
          'content_id': widget.idMessage,
          'access_token': widget.accessToken,
        },
      );
      final shareData = json.decode(shareRes.body);
      if (shareData['success'] == true) {
        print('✅ Đã share tin nhắn tới room $conversationId');
      } else {
        print('❌ Lỗi share: ${shareData['message']}');
      }
    }

    if (mounted) {
      setState(() => isSending = false); // 🛑 Xong thì dừng xoay
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0077BB);
    final keyword = _searchController.text.toLowerCase();
    final filtered = roomsAndFriends.where((item) {
      final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
      return title.contains(keyword);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Chia sẻ', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: primaryColor),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            if (_hasPreviewContent()) _buildMessagePreview(primaryColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bạn bè và nhóm',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? Center(child: Text('Không tìm thấy kết quả'))
                  : ListView(
                children: [
                  if (filtered.any((item) => !item.containsKey('name') || item.containsKey('members'))) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('Nhóm',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
                    ),
                    ...filtered.where((item) => !item.containsKey('name') || item.containsKey('members')).map((item) {
                      final id = item['id'].toString();
                      final title = (item['title'] != null && item['title'].toString().trim().isNotEmpty)
                          ? item['title']
                          : 'Nhóm ${item['id']}';
                      String? avatarUrl;
                      if (item['avatar'] is List && item['avatar'].isNotEmpty) {
                        avatarUrl = item['avatar'][0];
                      } else if (item['avatar'] is String && (item['avatar'] as String).isNotEmpty) {
                        avatarUrl = item['avatar'];
                      }
                      return CheckboxListTile(
                        value: selectedIds.contains(id),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              selectedIds.add(id);
                            } else {
                              selectedIds.remove(id);
                            }
                          });
                        },
                        activeColor: primaryColor,
                        checkColor: Colors.white,
                        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('${item['mcount'] ?? 0} thành viên',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        secondary: avatarUrl != null && avatarUrl.isNotEmpty
                            ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
                            : CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Icon(Icons.group, color: primaryColor),
                        ),
                      );
                    }).toList(),
                  ],
                  if (filtered.any((item) => item.containsKey('name') && !item.containsKey('members'))) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('Thành viên',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
                    ),
                    ...filtered.where((item) => item.containsKey('name') && !item.containsKey('members')).map((item) {
                      final id = item['id'].toString();
                      final title = item['name'] ?? '';
                      String? avatarUrl = (item['avatar'] != null && item['avatar'].toString().isNotEmpty)
                          ? item['avatar']
                          : null;
                      return CheckboxListTile(
                        value: selectedIds.contains(id),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              selectedIds.add(id);
                            } else {
                              selectedIds.remove(id);
                            }
                          });
                        },
                        activeColor: primaryColor,
                        checkColor: Colors.white,
                        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('User', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        secondary: avatarUrl != null && avatarUrl.isNotEmpty
                            ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
                            : CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Icon(Icons.person, color: primaryColor),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (selectedIds.isEmpty || isSending) ? null : shareMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isSending
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text('Gửi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPreviewContent() {
    return widget.text.isNotEmpty ||
        widget.link.isNotEmpty ||
        (widget.images.isNotEmpty && widget.images[0] != null) ||
        widget.files.isNotEmpty;
  }

  Widget _buildMessagePreview(Color primaryColor) {
    String? previewImage = widget.images.isNotEmpty ? widget.images[0] : null;
    String previewText = widget.text.isNotEmpty
        ? widget.text
        : widget.link.isNotEmpty
        ? widget.link
        : widget.files.isNotEmpty
        ? 'Có ${widget.files.length} tệp đính kèm'
        : 'Nội dung trống';

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Color(0xFFE6F2FA),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (previewImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(previewImage, width: 60, height: 60, fit: BoxFit.cover),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                previewText,
                style: TextStyle(fontSize: 14, color: Colors.black87),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }
}