import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationDetailScreen extends StatefulWidget {
  final String accessToken;
  final int notificationId;

  const NotificationDetailScreen({
    Key? key,
    required this.accessToken,
    required this.notificationId,
  }) : super(key: key);

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  Map<String, dynamic>? _notification;
  bool _isLoading = true;
  String? _error;


  @override
  void initState() {
    super.initState();
    _fetchNotificationDetail(widget.accessToken, widget.notificationId);

  }

  Future<void> _fetchNotificationDetail(String accessToken, int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/notification'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'access_token': accessToken.toString(),
          'id': notificationId.toString(),
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _notification = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Dữ liệu không hợp lệ');
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể tải chi tiết thông báo';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0077BB);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết thông báo',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _notification == null
          ? const Center(child: Text("Không có dữ liệu"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          color: isDark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFF1FAFE),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Text(
                  _notification!['title'] ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Nội dung
                Text(
                  _notification!['body'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? Colors.grey[200]
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Thời gian tạo
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _notification!['formatedCreatedDate'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey[400]
                            : Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),

                // Thời gian đã xem
                if (_notification!['read_at'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.done_all,
                          size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Đã xem lúc: ${_notification!['read_at']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
