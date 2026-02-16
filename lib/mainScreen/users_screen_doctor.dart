import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_chat_hospital/user/setting.dart';
import 'package:app_chat_hospital/user/member_screen.dart';
import 'package:app_chat_hospital/user/information_account_screen.dart';
import '../theme_mode_option.dart';
import '../models/user_info_small.dart';
import '../theme_preferences.dart';
import 'package:app_chat_hospital/user/attendance/attendance_screen.dart';
import 'package:app_chat_hospital/user/leave/leave_screen.dart';


class DoctorAccount extends StatefulWidget {
  final String userRole;
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;

  const DoctorAccount({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.userRole,
  });

  @override
  State<DoctorAccount> createState() => _DoctorAccountState();
}

class _DoctorAccountState extends State<DoctorAccount> {
  UserInfoSmall? _userInfo;
  bool _isLoading = true;
  late ThemeModeOption _currentTheme;


  @override
  void initState() {
    super.initState();
    _loadUserInfoFromPrefs();
    _currentTheme = widget.currentTheme;
  }

  Future<void> _loadUserInfoFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final avatar = prefs.getString('user_avatar') ?? '';
    final point = prefs.getString('user_point') ?? '0';

    setState(() {
      _userInfo = UserInfoSmall(name: name, avatar: avatar, point: point);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Cá nhân',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0077BB),
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

              setState(() {
                _currentTheme = newTheme;
              });
            },
          ),
          if (_userInfo != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      userRole: widget.userRole,
                      currentTheme: widget.currentTheme,
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InformationScreen(
                        showBackButton: true,
                        userRole: widget.userRole,
                        currentTheme: widget.currentTheme,
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    _loadUserInfoFromPrefs();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF0077BB),
                        backgroundImage: _userInfo!.avatar.startsWith('data:image')
                            ? MemoryImage(base64Decode(_userInfo!.avatar.split(',').last))
                            : _userInfo!.avatar.isNotEmpty
                            ? NetworkImage(_userInfo!.avatar)
                            : null,
                        child: _userInfo!.avatar.isEmpty
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userInfo!.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_userInfo!.point} điểm',
                              style: const TextStyle(
                                color: Color(0xFF0077BB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(Icons.person_outline, 'Tài khoản', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MemberInfoPage()),
              );
            }),
            _buildMenuCard(Icons.medical_information_outlined, 'Hồ sơ bệnh án', () {}),
            _buildMenuCard(Icons.calendar_month_outlined, 'Lịch khám bệnh', () {}),
            _buildMenuCard(Icons.work_history_outlined, 'Chấm công', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen()));
            }),
            _buildMenuCard(Icons.free_cancellation_outlined, 'Nghỉ phép', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LeaveScreen()));
            }),
            _buildMenuCard(Icons.note_alt_outlined, 'Ghi chú', () {}),
            _buildMenuCard(Icons.tune, 'Cấu hình', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF0077BB),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
