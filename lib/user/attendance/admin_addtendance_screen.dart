import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'tracking_log.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final Map<DateTime, String> _attendanceMap = {};
  DateTime _focusedDay = DateTime.now();
  int _totalTime = 0;
  int _lateDays = 0;
  int _halfDays = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchAttendance();
  }

  Future<void> _loadUserAndFetchAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    await _fetchAttendanceDates(userId);
  }

  Future<void> _fetchAttendanceDates(int userId) async {
    final url = Uri.parse('https://account.nks.vn/api/nks/user/attendances');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'user_id': userId.toString()},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      final option = json['option'];

      setState(() {
        _totalTime = option['total_time'] ?? 0;
        _lateDays = option['late'] ?? 0;
        _halfDays = option['halfday'] ?? 0;

        _attendanceMap.clear();
        for (var e in data) {
          final d = DateTime.parse(e['date']);
          final dateKey = DateTime(d.year, d.month, d.day);
          final status = e['status'] ?? '00';
          _attendanceMap[dateKey] = status;
        }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColor = const Color(0xFF0077BB);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm công'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildInfoTile('Thời gian làm việc', _totalTime, () {}, themeColor),
          _buildInfoTile('Số ngày đi trễ', _lateDays, () {}, themeColor),
          _buildInfoTile('Số ngày làm nửa buổi', _halfDays, () {}, themeColor),
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
                firstDay: DateTime.utc(_focusedDay.year - 1, 1, 1),
                lastDay: DateTime.utc(_focusedDay.year + 1, 12, 31),
                focusedDay: _focusedDay,
                onDaySelected: (selectedDay, focusedDay) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackingLog(date: selectedDay),
                    ),
                  );
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final dateKey = DateTime(day.year, day.month, day.day);

                    if (_attendanceMap.containsKey(dateKey)) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else if (dateKey.isBefore(today)) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 1.5),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }

                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final dateKey = DateTime(day.year, day.month, day.day);

                    if (_attendanceMap.containsKey(dateKey)) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.all(6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
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
                  todayDecoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.white),
                  defaultTextStyle: TextStyle(color: textColor),
                  weekendTextStyle: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey,
                  ),
                  markersMaxCount: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
