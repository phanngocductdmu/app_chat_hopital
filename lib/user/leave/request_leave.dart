import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  List<Map<String, dynamic>> _leaves = [];
  final Color themeColor = const Color(0xFF0077BB);
  String? fullname;
  String? userAvatar;
  int userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchLeaves();
  }

  Future<void> _loadUserAndFetchLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id') ?? 0;
    fullname = prefs.getString('user_name') ?? '';
    userAvatar = prefs.getString('user_avatar') ?? '';
    await _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    final url = Uri.parse('https://account.nks.vn/api/nks/leaves');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'user_id': userId.toString()},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        _leaves = List<Map<String, dynamic>>.from(json['data']);
      });
    }
  }

  Future<void> _deleteLeave(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa đơn nghỉ phép này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final url = Uri.parse('https://account.nks.vn/api/nks/leave/delete');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'leave_id': id.toString(),
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final success = json['success'] == true;

      if (success) {
        setState(() {
          _leaves.removeWhere((leave) => leave['id'] == id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa đơn nghỉ phép thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json['message'] ?? 'Xóa thất bại')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xảy ra lỗi khi xóa đơn nghỉ phép')),
      );
    }
  }

  String formatDate(dynamic datetime) {
    if (datetime == null) return '---';
    final str = datetime.toString();
    if (!str.contains(' ')) return '---';
    final datePart = str.split(' ').first;
    final parts = datePart.split('-');
    if (parts.length != 3) return datePart;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Request leave"),
        foregroundColor: Colors.white,
        backgroundColor: themeColor,
        elevation: 2,
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaves.length,
        itemBuilder: (context, index) {
          final leave = _leaves[index];
          final fullname = leave['fullname'] ?? '';
          final type = leave['type']?.toString() ?? '';
          final reason = leave['reason']?.toString() ?? '';
          final approvalAt = leave['approval_at'];
          final rejectedAt = leave['rejected_at'];
          final isHalfday = leave['halfday'] == true;
          final begin = formatDate(leave['begin_at']);
          final end = formatDate(leave['end_at']);
          final leaveId = leave['id'];

          // Màu nền theo trạng thái
          Color statusColor = Colors.white;
          if (approvalAt != null) statusColor = const Color(0xFFE6F4EA);
          if (rejectedAt != null) statusColor = const Color(0xFFFDEAEA);

          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên người + nút xoá
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    if (approvalAt == null && rejectedAt == null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Xoá đơn',
                        onPressed: () => _deleteLeave(leaveId),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Thời gian
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0077BB)),
                    const SizedBox(width: 6),
                    Text(
                      isHalfday ? 'Nghỉ nửa ngày: $begin' : '$begin - $end',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Loại đơn
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      type,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Nội dung đơn nghỉ
                if (reason.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}