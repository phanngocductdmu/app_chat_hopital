import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'image_preview_screen.dart';
import 'share_screen.dart';

class ChatList extends StatefulWidget {
  final String conversationId;
  final String accessToken;
  final void Function(String id, String text) onReply;

  const ChatList({
    super.key,
    required this.conversationId,
    required this.accessToken,
    required this.onReply,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  bool _showScrollToBottom = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  int? selectedMessageIndex;
  bool _isLoadingLink = false;
  List<String> previewImages = [];
  int initialPreviewIndex = 0;
  String? highlightedMessageId;


  @override
  void initState() {
    super.initState();
    fetchMessages();
    onNewMessage = fetchMessages;
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToBottom) {
        setState(() {
          _showScrollToBottom = true;
        });
      } else if (_scrollController.offset <= 300 && _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = false;
        });
      }
    });
  }

  Future<void> fetchMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id')?.toString() ?? '';

    final url = Uri.parse('https://account.nks.vn/api/nks/user/conversation');
    final response = await http.post(
      url,
      body: {
        'id': widget.conversationId,
        'access_token': widget.accessToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final messageList = data['data']['messages'] as List<dynamic>;
        setState(() {
          messages = messageList.map<Map<String, dynamic>>((msg) {
            final reply = msg['reply'];
            final linkPreview = msg['link_preview'];

            return {
              'id': msg['id'].toString(),
              'text': msg['body'] ?? '',
              'link': msg['link'] ?? '',
              'replyId': msg['reply_id']?.toString() ?? '',
              'isMe': msg['user_id'].toString() == currentUserId,
              'time': DateFormat('HH:mm dd/MM/yyyy').parse(msg['formatedDate'] ?? ''),
              'avatar': msg['useravatar'] ?? '',
              'images': (msg['image'] is List)
                  ? msg['image']
                  : (msg['image'] != null ? [msg['image']] : []),
              'files': (msg['files'] is List)
                  ? msg['files']
                  : (msg['files'] != null ? [msg['files']] : []),
              'replyBody': reply != null ? reply['body'] ?? '' : '',
              'replyImage': reply != null ? reply['image'] ?? '' : '',
              'linkPreview': linkPreview != null
                  ? {
                'title': linkPreview['title'] ?? '',
                'image_src': linkPreview['image_src'] ?? '',
                'body': linkPreview['body'] ?? '',
                'path': linkPreview['path'] ?? '',
              }
                  : null,
              'key': GlobalKey(),
            };
          }).toList();

        });
      }
    } else {
      print('❌ HTTP error: ${response.statusCode}');
    }
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Không thể mở $url';
    }
  }

  void _showMessageOptions(BuildContext context, String idMessage, String text, List images, String link, List files,) {
    showModalBottomSheet(context: context, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16)),), builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  icon: Icons.undo,
                  label: 'Thu hồi',
                  color: Color(0xff0077bb),
                  onTap: () {
                    Navigator.of(context).pop();
                    _recallMessage(idMessage);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.share,
                  label: 'Chia sẻ',
                  color: Color(0xff0077bb),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareMessage(idMessage, text, images, link, files);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.delete,
                  label: 'Xoá phía tôi',
                  color: Color(0xff0077bb),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteMessage(idMessage);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.reply,
                  label: 'Trả lời',
                  color: Color(0xff0077bb),
                  onTap: () {
                    Navigator.of(context).pop();
                    _replyMessage(idMessage, text);
                  },
                ),
              ],
            ),
          ),
        );
      },);
  }

  void _replyMessage(String idMessage, String text) {
    widget.onReply(idMessage, text);
  }

  void scrollToReply(String replyId) async {
    final index = messages.indexWhere((msg) => msg['id'] == replyId);
    if (index != -1) {
      // Cuộn gần đến đó
      final position = index * 80.0; // ước tính chiều cao, tuỳ layout
      try {
        await _scrollController.animateTo(
          position,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (_) {}

      // Sau frame để widget render xong
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = messages[index]['key'] as GlobalKey;
        final context = key.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: Duration(milliseconds: 200),
            alignment: 0.1,
          );
        }

        // Bật highlight
        setState(() {
          highlightedMessageId = replyId;
        });

        // Sau 1 giây tắt highlight
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              highlightedMessageId = null;
            });
          }
        });
      });
    }
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _recallMessage(String index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thu hồi tin nhắn')),
    );
  }

  void _shareMessage(
      String idMessage,
      String text,
      List images,
      String link,
      List files,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareScreen(
          idMessage: idMessage,
          text: text,
          images: images,
          link: link,
          files: files,
          accessToken: widget.accessToken,
          conversationId: widget.conversationId,
        ),
      ),
    );
  }

  void _deleteMessage(String index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xoá tin nhắn phía tôi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          selectedMessageIndex = null;
        });
      },
      child: Stack(
        children: [
          Container(
            color: backgroundColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['isMe'] as bool;
                final isSelected = selectedMessageIndex == index;
                bool showAvatar = false;
                if (!isMe) {
                  final isFirst = index == 0;
                  final prevIsMe = !isFirst && (messages[index - 1]['isMe'] == true);
                  if (isFirst || prevIsMe) {
                    showAvatar = true;
                  }
                }
                return GestureDetector(
                  key: msg['key'],
                  onTap: () {
                    if (isMe) {
                      setState(() {
                        selectedMessageIndex = isSelected ? null : index;
                      });
                    }
                  },
                  onLongPress: () {
                    _showMessageOptions(
                      context,
                      msg['id'],
                      msg['text'],
                      msg['images'],
                      msg['link'],
                      msg['files'],
                    );
                  },
                  child: _buildMessage(context, msg, isSelected, isDark, showAvatar),
                );
              },
            ),
          ),

          // Thêm nút nhỏ ở dưới bên phải
          if (_showScrollToBottom)
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  _scrollController.animateTo(
                    0.0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Icon(Icons.keyboard_double_arrow_down, color: Color(0xff0077bb), size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, Map<String, dynamic> message, bool isSelected, bool isDark, bool showAvatar,) {
    final isHighlighted = message['id'] == highlightedMessageId;
    final isMe = message['isMe'] as bool;
    final text = message['text'] as String;
    final String link = message['link'] ?? '';
    final DateTime time = message['time'] as DateTime;
    final timeString = DateFormat.Hm().format(time);
    final avatarUrl = message['avatar'] as String?;
    final images = (message['images'] ?? []) as List;
    final messageTextColor = isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black87);
    final timeTextColor = isMe ? Colors.white70 : (isDark ? Colors.grey[400] : Colors.black45);
    final replyBody = message['replyBody'] as String;
    final replyImage = message['replyImage'] as String;
    final replyId = message['replyId'] as String;
    final linkPreview = message['linkPreview'];

    final messageBg = isMe
        ? BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0077BB), Color(0xFF66B2FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    )
        : BoxDecoration(
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
      ],
    );

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isHighlighted
            ? Color(0xFF66B2FF).withOpacity(0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: showAvatar
                      ? CircleAvatar(
                    radius: 16,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    backgroundColor: const Color(0xFF0077BB),
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 16)
                        : null,
                  )
                      : const SizedBox(width: 32),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (images.isNotEmpty && text.isEmpty)
                    Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: () {
                              if (images.length == 1) {
                                return _buildImageItem(
                                  images.first,
                                  context,
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  height: 200,
                                );
                              } else if (images.length == 4) {
                                return GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                  physics: NeverScrollableScrollPhysics(),
                                  children: images.map<Widget>((url) {
                                    return _buildImageItem(url, context);
                                  }).toList(),
                                );
                              } else {
                                final itemWidth = (MediaQuery.of(context).size.width * 0.7 - 12) / 3;
                                return Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Wrap(
                                    alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: images.map<Widget>((url) {
                                      return _buildImageItem(url, context, width: itemWidth, height: 100);
                                    }).toList(),
                                  ),
                                );
                              }
                            }(),
                          ),
                        ),
                      ],
                    ),
                  if (text.isNotEmpty || link.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: messageBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (replyBody.isNotEmpty || replyImage.isNotEmpty)
                            InkWell(
                              onTap: () {
                                scrollToReply(replyId);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.white24 : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IntrinsicWidth(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (replyImage.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                            replyImage,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      if (replyImage.isNotEmpty)
                                        const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          replyBody,
                                          style: TextStyle(
                                            color: isMe ? Colors.white70 : Colors.black87,
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (images.isNotEmpty && text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: images.map<Widget>((url) {
                                  final itemWidth = (MediaQuery.of(context).size.width * 0.7 - 12) / 3;
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: GestureDetector(
                                      onTap: () {
                                        final allImages = messages
                                            .expand((msg) => List<String>.from(msg['images'] ?? []))
                                            .toList();
                                        final clickedIndex = allImages.indexOf(url);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ImagePreviewScreen(
                                              images: allImages,
                                              initialIndex: clickedIndex,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        url,
                                        width: itemWidth,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (text.isNotEmpty)
                            Text(
                              text,
                              style: TextStyle(color: messageTextColor, fontSize: 15, height: 1.3),
                            ),
                          if (linkPreview != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: InkWell(
                                onTap: () async {
                                  setState(() => _isLoadingLink = true);
                                  try {
                                    await openUrl(linkPreview['path'] ?? '');
                                  } catch (e) {} finally {
                                    setState(() => _isLoadingLink = false);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue[50] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          linkPreview['image_src'] ?? '',
                                          width: double.infinity,
                                          height: 160,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey[300],
                                            height: 160,
                                            child: Icon(Icons.public, size: 48, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        linkPreview['title'] ?? '',
                                        style: TextStyle(
                                          color: isMe ? Colors.blue[800] : Colors.black87,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        linkPreview['body'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        linkPreview['path'] ?? '',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_isLoadingLink)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            timeString,
                            style: TextStyle(color: timeTextColor, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  if (text.isEmpty && link.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        timeString,
                        style: TextStyle(color: Colors.black54, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(String url, BuildContext context, {double? width, double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () {
          final allImages = messages
              .expand((msg) => List<String>.from(msg['images'] ?? []))
              .toList();
          final clickedIndex = allImages.indexOf(url);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImagePreviewScreen(
                images: allImages,
                initialIndex: clickedIndex,
              ),
            ),
          );
        },
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  void dispose() {
    onNewMessage = null;
    super.dispose();
  }
}