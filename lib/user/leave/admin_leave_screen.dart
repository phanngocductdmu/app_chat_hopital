import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'admin_request_leave.dart';


class AdminleaveScreen extends StatelessWidget {
  const AdminleaveScreen({super.key});

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
    final themeColor = const Color(0xFF0077BB);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.hourglass_bottom),
            tooltip: 'Xem chi tiết thời gian',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdminRequestLeaveScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm mới',
            onPressed: () {
              // Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => AddAdminleaveScreen()));
            },
          ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildInfoTile('Số ngày phép năm', 15, () {
          }, themeColor),
          _buildInfoTile('Số ngày phép đã dùng', 0, () {
          }, themeColor),
          _buildInfoTile('Số ngày phép còn lại', 0, () {
          }, themeColor),
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
                  weekendTextStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}