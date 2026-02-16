import 'package:flutter/material.dart';
import '../theme_mode_option.dart';
import '../theme_preferences.dart';
import '../user/leave/admin_leave_screen.dart';
import '../user/setting.dart';
import 'package:app_chat_hospital/user/attendance/admin_addtendance_screen.dart';

class AdminScreen extends StatefulWidget {
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;
  final String userRole;

  const AdminScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.userRole,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late ThemeModeOption _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final appBarColor = isDark ? Colors.black : const Color(0xff0077bb);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Cá nhân',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: appBarColor,
        actions: [
          IconButton(
            icon: Icon(
              _currentTheme == ThemeModeOption.dark
                  ? Icons.wb_sunny_outlined
                  : Icons.nights_stay_outlined,
              color: Colors.white,
            ),
            onPressed: () async {
              final newTheme = _currentTheme == ThemeModeOption.dark
                  ? ThemeModeOption.light
                  : ThemeModeOption.dark;
              await ThemePreferences.saveTheme(newTheme);
              widget.onThemeChanged(newTheme);
              setState(() => _currentTheme = newTheme);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    userRole: widget.userRole,
                    currentTheme: _currentTheme,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            _AdminMenuItem(icon: Icons.person_outline, label: 'Patient', onTap: () {}),
            _AdminMenuItem(icon: Icons.calendar_today, label: 'Appointment', onTap: () {}),
            _AdminMenuItem(icon: Icons.medication_outlined, label: 'Prescription', onTap: () {}),
            _AdminMenuItem(icon: Icons.local_hospital, label: 'Doctor', onTap: () {}),
            _AdminMenuItem(icon: Icons.apartment, label: 'Hospital', onTap: () {}),
            _AdminMenuItem(icon: Icons.local_pharmacy, label: 'Pharmacy', onTap: () {}),
            _AdminMenuItem(
              icon: Icons.access_time,
              label: 'Attendance',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
              ),
            ),
            _AdminMenuItem(
              icon: Icons.beach_access,
              label: 'Leave',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminleaveScreen()),
              ),
            ),
            _AdminMenuItem(icon: Icons.more_horiz, label: 'More', onTap: () {}),
          ],
        ),
      ),
    );
  }
}
class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = isDark ? Colors.transparent : Colors.grey.withOpacity(0.15);

    return Material(
      color: bgColor,
      elevation: 3,
      shadowColor: shadowColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: const Color(0xFF0077BB)),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}