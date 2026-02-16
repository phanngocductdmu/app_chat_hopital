import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'media_gallery_screen.dart';
import 'add_members.dart';

class ChatOptionsScreen extends StatefulWidget {
  final String id;
  final String accessToken;

  const ChatOptionsScreen({
    super.key,
    required this.id,
    required this.accessToken,
  });

  @override
  State<ChatOptionsScreen> createState() => _ChatOptionsScreenState();
}

class _ChatOptionsScreenState extends State<ChatOptionsScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> members = [];
  List<dynamic> medias = [];
  List<String> allMediaUrls = [];
  List<dynamic> allInGroup = [];
  List<dynamic> links = [];
  List<dynamic> files = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final url = Uri.parse('https://account.nks.vn/api/nks/user/conversation');
      final response = await http.post(url, body: {
        'id': widget.id,
        'access_token': widget.accessToken,
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final d = json['data'];
          // Gom tất cả media url thành List<String>
          List<String> mediaUrls = [];
          if (d['medias'] is List) {
            for (var item in d['medias']) {
              if (item is Map && item['medias'] is List) {
                mediaUrls.addAll(item['medias'].cast<String>());
              }
            }
          }
          setState(() {
            data = d;
            members = d['members'] is List ? d['members'] : [];
            allInGroup = d['allInGroup'] is List ? d['allInGroup'] : [];
            medias = d['medias'] is List ? d['medias'] : [];
            links = d['links'] is List ? d['links'] : [];
            files = d['files'] is List ? d['files'] : [];
            allMediaUrls = mediaUrls;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'API trả về lỗi hoặc dữ liệu trống';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Lỗi API: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF0077BB);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Tùy chọn', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(primaryColor),
            const SizedBox(height: 20),
            _sectionTitle('Kho media', primaryColor),
            const SizedBox(height: 8),
            allMediaUrls.isNotEmpty
                ? GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaGalleryScreen(
                      medias: medias,
                      links: links,
                      files: files,
                    ),
                  ),
                );
              },
              child: Row(
                children: List.generate(
                  allMediaUrls.length > 5 ? 5 : allMediaUrls.length,
                      (index) {
                    if (index == 4 && allMediaUrls.length > 5) {
                      final more = allMediaUrls.length - 4;
                      return _mediaItem(allMediaUrls[index], overlayText: '+$more');
                    }
                    return _mediaItem(allMediaUrls[index]);
                  },
                ),
              ),
            )
                :Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              ],
            ),

            const SizedBox(height: 20),
            if (members.length <= 2)
              _optionTile(Icons.group, 'Nhóm chung (${allInGroup.length})', primaryColor, () {}),
            _optionTile(Icons.person_add_alt, 'Thêm thành viên (${members.length})', primaryColor, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMembers(
                    id: widget.id,
                    accessToken: widget.accessToken,
                    members: members,
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            _sectionTitle('Thành viên', primaryColor),
            const SizedBox(height: 8),
            ...members.map((m) {
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(m['avatar'] ?? 'https://via.placeholder.com/150'),
                  ),
                  title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(m['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            _dangerTile(Icons.delete_forever, 'Giải tán nhóm', () {}),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(Color primaryColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(
            (data?['avatar'] as List?)?.isNotEmpty == true
                ? data!['avatar'][0]
                : 'https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png',
          ),
        ),
        title: Text(
          members.isNotEmpty ? members[0]['name'] ?? '' : '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text('ID: ${data?['id'] ?? ''}', style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _mediaItem(String url, {String? overlayText}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
          child: overlayText != null
              ? Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              overlayText,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          )
              : null,
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _dangerTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        onTap: onTap,
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
    );
  }
}