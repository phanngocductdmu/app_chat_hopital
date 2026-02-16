import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../message/chat_screen.dart';
import '../main.dart';
import '../message/create_message_screen.dart';

class MessageScreenDoctor extends StatefulWidget {
  const MessageScreenDoctor({super.key});
  @override
  State<MessageScreenDoctor> createState() => _MessageScreenDoctorState();
}

class _MessageScreenDoctorState extends State<MessageScreenDoctor> {
  List<dynamic> conversations = [];
  String accessToken = '';
  int idUser = 0;
  @override
  void initState() {
    super.initState();
    fetchConversations();
    onNewMessage = fetchConversations;
  }

  Future<void> fetchConversations() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      final id = prefs.getInt('user_id') ?? 0;
      setState(() {
        accessToken = token;
        idUser = id;
      });

      if (accessToken.isEmpty) {
        print('⚠️ accessToken is empty');
        return;
      }

      final response = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/conversations'),
        body: {'access_token': accessToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            conversations = data['data'];
          });
        } else {
          print('❌ API success = false');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Color(0xfffcfcfc),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isDark ? Colors.black : const Color(0xFF0077BB),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            tooltip: 'Tạo tin nhắn',
            onPressed: () async {
              final shouldReload = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateMessageScreen(
                    idUser: idUser,
                    accessToken: accessToken,
                  ),
                ),
              );
              if (shouldReload == true) {
                fetchConversations();
              }
            },
          ),
        ],
      ),
      body: _buildConversationList(context),
    );
  }

  Widget _buildConversationList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (conversations.isEmpty) {
      return Center(
        child: Text(
          'Chưa có cuộc trò chuyện.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final convo = conversations[index];
        final id = convo['id'];
        final rawTitle = convo['title']?.toString().trim();
        final title = (rawTitle?.isNotEmpty == true) ? rawTitle! : 'Nhóm $id';
        final avatarList = List<String>.from(convo['avatar'] ?? []);
        final time = convo['formatedCreatedDate'] ?? '';
        final textChat = convo['body'] ?? 'Tin nhắn';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final shouldReload = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    accessToken: accessToken,
                    conversationId: convo['id'].toString(),
                  ),
                ),
              );

              if (shouldReload == true) {
                fetchConversations();
              }
            },

            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.17),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: avatarList.isNotEmpty
                        ? NetworkImage(avatarList.first)
                        : null,
                    backgroundColor: const Color(0xFF0077BB),
                    child: avatarList.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          textChat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    onNewMessage = null;
    super.dispose();
  }
}