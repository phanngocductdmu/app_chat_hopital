import 'package:flutter/material.dart';
import 'chat_list.dart';
import 'chat_input.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'chat_options_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String accessToken;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.accessToken,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [];
  final ScrollController _scrollController = ScrollController();

  String fullName = '';
  int memberCount = 0;
  String? replyId;
  String? replyText;

  @override
  void initState() {
    super.initState();
    currentScreen = 'in';
    onScreenChanged?.call('in');
    _loadConversationInfo();
  }

  Future<void> _loadConversationInfo() async {
    try {
      final url = Uri.parse('https://account.nks.vn/api/nks/user/conversation');
      final response = await http.post(
        url,
        body: {
          'id': widget.conversationId,
          'access_token': widget.accessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            fullName = data['data']['id'].toString();
            memberCount = data['data']['mcount'] ?? 0;
          });
        } else {
          print('API trả về lỗi: ${data['message']}');
        }
      } else {
        print('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add({
        'text': text,
        'isMe': true,
        'time': DateTime.now(),
        'status': 'Đã xem',
      });
    });

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add({
          'text': 'Bác sĩ trả lời: $text',
          'isMe': false,
          'time': DateTime.now(),
          'status': 'Đã xem',
        });
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void onReplyMessage(String id, String text) {
    setState(() {
      replyId = id;
      replyText = text;
    });
  }

  void onCancelReply() {
    setState(() {
      replyId = null;
      replyText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF0077BB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE2E9F1),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_sharp, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatOptionsScreen(
                  accessToken: widget.accessToken,
                  id: widget.conversationId,
                ),
              ),
            );

            if (result == true) {
              _loadConversationInfo();
            }

          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhóm $fullName',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '$memberCount thành viên',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
          actions: [
          IconButton(
            icon: const Icon(Icons.view_headline),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatOptionsScreen(
                    accessToken: widget.accessToken,
                    id: widget.conversationId,
                  ),
                ),
              );
              if (result == true) {
                _loadConversationInfo();
              }
            },
            color: Colors.white,
          ),
        ],

      ),
      body: Column(
        children: [
          Expanded(
            child: ChatList(
              accessToken: widget.accessToken,
              conversationId: widget.conversationId,
              onReply: onReplyMessage,
            ),
          ),
          ChatInput(
            onSend: _sendMessage,
            accessToken: widget.accessToken,
            conversationId: widget.conversationId,
            replyId: replyId,
            replyText: replyText,
            onCancelReply: onCancelReply,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    currentScreen = 'out';
    onScreenChanged?.call('out');
    _scrollController.dispose();
    super.dispose();
  }
}
