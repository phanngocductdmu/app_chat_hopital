import 'dart:convert';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ChatInput extends StatefulWidget {
  final void Function(String text) onSend;
  final String conversationId;
  final String accessToken;
  final String? replyId;
  final String? replyText;
  final VoidCallback? onCancelReply;

  const ChatInput({
    super.key,
    required this.onSend,
    required this.conversationId,
    required this.accessToken,
    this.replyId,
    this.replyText,
    this.onCancelReply,
  });

  @override
  ChatInputState createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  List<File> selectedImages = [];
  File? selectedFile;
  String? selectedFileName;
  bool _showEmojiPicker = false;

  void _onTextChanged(String text) {
    setState(() {
      _isTyping = text.trim().isNotEmpty || selectedImages.isNotEmpty;
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        selectedFileName = result.files.single.name;
        _isTyping = true;
      });
    }
  }

  Future<void> _openCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          selectedImages.add(File(pickedFile.path));
          _isTyping = true;
        });
      }
    } catch (e) {
      print('⚠️ Lỗi mở camera: $e');
    }
  }

  Future<void> _handleSend() async {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty && selectedImages.isEmpty && selectedFile == null) return;
    final urlRegex = RegExp(r'(https?:\/\/[^\s]+)');
    final matches = urlRegex.allMatches(rawText);
    String link = "";
    String body = rawText;
    if (matches.isNotEmpty) {
      link = matches.first.group(0) ?? "";
      body = rawText.replaceAll(link, "").trim();
    }

    // media vẫn để base64 hoặc cũng có thể đổi thành MultipartFile tương tự
    final base64List = selectedImages.map((file) {
      final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
      final b64 = base64Encode(file.readAsBytesSync());
      return 'data:$mime;base64,$b64';
    }).toList();
    final mediaBase64 = base64List.join('|');
    widget.onCancelReply?.call();
    _controller.clear();
    setState(() {
      _isTyping = false;
      selectedImages.clear();
      selectedFile = null;
      selectedFileName = null;
    });

    try {
      var uri = Uri.parse("https://account.nks.vn/api/nks/user/conversation/send");
      var request = http.MultipartRequest('POST', uri);
      // Thêm các trường text bình thường
      request.fields['id'] = widget.conversationId;
      request.fields['body'] = body;
      request.fields['access_token'] = widget.accessToken;
      request.fields['media'] = mediaBase64;
      request.fields['link'] = link;
      request.fields['reply_id'] = widget.replyId ?? "";
      // Thêm file nếu có
      if (selectedFile != null) {
        final mime = lookupMimeType(selectedFile!.path) ?? 'application/octet-stream';
        final bytes = selectedFile!.readAsBytesSync();
        final b64 = base64Encode(bytes);

        final fileBase64 = 'data:$mime;base64,$b64';
        print('📦 File base64 ready: $fileBase64');
      }
      var response = await request.send();
      if (response.statusCode == 200) {
        widget.onCancelReply?.call();
      } else {
        print('❌ Lỗi HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Exception: $e');
    }
  }

  Future<void> _showImagePicker() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) return;
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;
    final photos = await albums[0].getAssetListPaged(page: 0, size: 100);
    final thumbnails = await Future.wait(photos.map((e) => e.thumbnailDataWithSize(ThumbnailSize(200, 200))));

    final ValueNotifier<Set<String>> selectedIds = ValueNotifier<Set<String>>({});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Stack(
            children: [
              DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return GridView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final thumb = thumbnails[index];
                      if (thumb == null) return Container(color: Colors.grey[200]);
                      final id = photos[index].id;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (selectedIds.value.contains(id)) {
                              selectedIds.value = {...selectedIds.value}..remove(id);
                            } else {
                              selectedIds.value = {...selectedIds.value}..add(id);
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(thumb, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                            ),
                            ValueListenableBuilder<Set<String>>(
                              valueListenable: selectedIds,
                              builder: (_, selected, __) {
                                final isSelected = selected.contains(id);
                                return Positioned(
                                  top: 4, right: 4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isSelected ? Colors.blue : Colors.black26,
                                    child: Icon(isSelected ? Icons.check : Icons.radio_button_unchecked, color: Colors.white, size: 14),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: selectedIds,
                builder: (_, selected, __) {
                  if (selected.isEmpty) return SizedBox.shrink();
                  return Positioned(
                    bottom: 16, right: 16,
                    child: FloatingActionButton.extended(
                      backgroundColor: Color(0xff0077bb),
                      icon: Icon(Icons.done, color: Colors.white),
                      label: Text('Chọn (${selected.length})', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        final files = await Future.wait(photos.where((e) => selected.contains(e.id)).map((e) => e.file));
                        setState(() {
                          selectedImages.addAll(files.whereType<File>());
                          _isTyping = true;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Color(0xff121212) : Color(0xfff0f4f8);
    final inputBg = isDark ? Colors.grey[800] : Colors.white;
    final iconColor = Color(0xff0077bb);

    return SafeArea(
      child: Container(
        color: backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedImages.isNotEmpty)
              Container(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (_, index) {
                    final file = selectedImages[index];
                    return Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImages.removeAt(index);
                                _isTyping = _controller.text.trim().isNotEmpty || selectedImages.isNotEmpty;
                              });
                            },
                            child: CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (widget.replyId != null && widget.replyText != null)
              Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Trả lời: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.replyText!,
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelReply,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.close, size: 18),
                      ),
                    )
                  ],
                ),
              ),
            if (selectedFile != null)
              Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedFileName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFile = null;
                          selectedFileName = null;
                          _isTyping = _controller.text.trim().isNotEmpty || selectedImages.isNotEmpty;
                        });
                      },
                      child: Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.emoji_emotions_outlined, color: iconColor, size: 24),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                            });
                          },
                          splashRadius: 20,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 5,
                            onChanged: _onTextChanged,
                            onTap: () {
                              if (_showEmojiPicker) {
                                setState(() {
                                  _showEmojiPicker = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),

                SizedBox(width: 6),
                _isTyping
                    ? _buildSendButton()
                    : _buildActionButtons(iconColor),
              ],
            ),
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _controller.text += emoji.emoji;
                    _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length));
                    _onTextChanged(_controller.text);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF0077BB), Color(0xFF66B2FF)]),
      ),
      child: IconButton(
        icon: Icon(Icons.send, color: Colors.white),
        onPressed: _handleSend,
        splashRadius: 22,
      ),
    );
  }

  Widget _buildActionButtons(Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircleIcon(Icons.attach_file, iconColor, _pickFile),
        SizedBox(width: 4),
        _buildCircleIcon(Icons.camera_alt_outlined, iconColor, _openCamera),
        SizedBox(width: 4),
        _buildCircleIcon(Icons.image_outlined, iconColor, _showImagePicker),
      ],
    );
  }

  Widget _buildCircleIcon(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: color, size: 20), onPressed: onTap, splashRadius: 20),
    );
  }
}
