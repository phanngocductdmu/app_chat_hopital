import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'request_leave.dart';
import 'add_leave.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final Color themeColor = const Color(0xFF0077BB);
  Map<DateTime, Color> leaveColors = {};
  int totalLeaveDays = 15;
  int usedLeaveDays = 0;
  int remainingLeaveDays = 15;

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    final url = Uri.parse('https://account.nks.vn/api/nks/leaves');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'user_id': userId.toString()},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = List<Map<String, dynamic>>.from(json['data']);

      final Map<DateTime, Color> colorMap = {};
      int totalUsed = 0;

      for (var leave in data) {
        final beginAt = leave['begin_at']?.split(' ')?.first;
        final endAt = leave['end_at']?.split(' ')?.first;

        final beginDate = beginAt != null ? DateTime.tryParse(beginAt) : null;
        final endDate = endAt != null ? DateTime.tryParse(endAt) : beginDate;

        if (beginDate == null) continue;

        // Đếm số ngày đã duyệt
        if (leave['approval_at'] != null) {
          final end = endDate ?? beginDate;
          final days = end.difference(beginDate).inDays + 1;
          totalUsed += days;
        }

        // Màu trạng thái
        Color statusColor;
        if (leave['approval_at'] != null) {
          statusColor = Colors.green;
        } else if (leave['rejected_at'] != null) {
          statusColor = Colors.red;
        } else {
          statusColor = themeColor;
        }

        // Gán màu từng ngày
        for (DateTime d = beginDate;
        !d.isAfter(endDate!);
        d = d.add(const Duration(days: 1))) {
          colorMap[DateTime(d.year, d.month, d.day)] = statusColor;
        }
      }

      setState(() {
        leaveColors = colorMap;
        usedLeaveDays = totalUsed;
        remainingLeaveDays = totalLeaveDays - usedLeaveDays;
      });
    }
  }

  Widget _buildInfoTile(String title, int count, VoidCallback onTap, Color themeColor) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: CircleAvatar(
          backgroundColor: themeColor,
          radius: 16,
          child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nghỉ phép'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.hourglass_bottom),
            tooltip: 'Xem chi tiết thời gian',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RequestLeaveScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm mới',
            onPressed: () {
              if (remainingLeaveDays <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Bạn đã hết số ngày phép trong năm.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddLeaveScreen()));
            },
          ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildInfoTile('Số ngày phép năm', totalLeaveDays, () {}, themeColor),
          _buildInfoTile('Số ngày phép đã dùng', usedLeaveDays, () {}, themeColor),
          _buildInfoTile('Số ngày phép còn lại', remainingLeaveDays, () {}, themeColor),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(today.year - 1, 1, 1),
                lastDay: DateTime.utc(today.year + 1, 12, 31),
                focusedDay: today,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                  leftChevronIcon: Container(
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  rightChevronIcon: Container(
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayTextStyle: const TextStyle(color: Colors.white),
                  defaultTextStyle: TextStyle(color: textColor),
                  weekendTextStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey),
                  outsideTextStyle: const TextStyle(color: Colors.grey),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final color = leaveColors[DateTime(day.year, day.month, day.day)];
                    if (color != null) {
                      return Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB0C4F9),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}