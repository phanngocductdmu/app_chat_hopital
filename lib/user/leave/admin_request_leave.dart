import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminRequestLeaveScreen extends StatefulWidget {
  const AdminRequestLeaveScreen({super.key});

  @override
  State<AdminRequestLeaveScreen> createState() => _AdminRequestLeaveScreenState();
}

class _AdminRequestLeaveScreenState extends State<AdminRequestLeaveScreen> {
  List<Map<String, dynamic>> _leaves = [];
  final Color themeColor = const Color(0xFF0077BB);

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    final url = Uri.parse('https://account.nks.vn/api/nks/leaves');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final allLeaves = List<Map<String, dynamic>>.from(json['data']);
      setState(() {
        _leaves = allLeaves;
      });
    }
  }

  Future<void> _approveLeave(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final url = Uri.parse('https://account.nks.vn/api/nks/leave/approve');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'leave_id': id.toString(),
        'user_id': userId.toString(),
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _leaves.removeWhere((leave) => leave['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã duyệt đơn nghỉ phép')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi duyệt đơn')),
      );
    }
  }


  Future<void> _rejectLeave(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final url = Uri.parse('https://account.nks.vn/api/nks/leave/reject');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'leave_id': id.toString(),
        'user_id': userId.toString(),
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _leaves.removeWhere((leave) => leave['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối đơn nghỉ phép')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi từ chối đơn')),
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
          final begin = formatDate(leave['begin_at']);
          final end = formatDate(leave['end_at']);
          final type = leave['type'] ?? '';
          final approvalAt = leave['approval_at'];
          final rejectedAt = leave['rejected_at'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                // Hàng đầu: Họ tên + thời gian + loại đơn + icon xử lý
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullname,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0077BB)),
                              const SizedBox(width: 6),
                              Text(
                                '$begin - $end',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_alt_outlined, size: 16, color: Colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  leave['reason'] ?? '(Không có lý do)',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (approvalAt == null && rejectedAt == null)
                      const Icon(Icons.pending_actions, color: Color(0xFF0077BB)),
                    if (approvalAt != null)
                      const Icon(Icons.check_circle, color: Colors.green),
                    if (rejectedAt != null)
                      const Icon(Icons.cancel, color: Colors.red),
                  ],
                ),
                const SizedBox(height: 16),

                // Nếu đơn chưa xử lý thì hiển thị 2 nút
                if (approvalAt == null && rejectedAt == null)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveLeave(leave['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077BB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _rejectLeave(leave['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
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
