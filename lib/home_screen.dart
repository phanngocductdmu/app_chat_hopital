import 'package:app_chat_hospital/theme_mode_option.dart';
import 'package:flutter/material.dart';
import 'mainScreen/main_creen_patient.dart';
import 'mainScreen/message_screen_doctor.dart';
import 'mainScreen/users_screen_doctor.dart';
import 'mainScreen/main_screen_doctor.dart';
import 'mainScreen/message_screen_patient.dart';
import 'mainScreen/users_screen_admin.dart';


class HomeScreen extends StatefulWidget {
  final String userRole;
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;

  const HomeScreen({super.key, required this.userRole, required this.currentTheme, required this.onThemeChanged});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens {
    return [
      (widget.userRole == 'doctor' || widget.userRole == 'SoftAdmin')
          ? const MainScreenDoctor()
          : const MainScreenPatient(),

      const MessageScreenDoctor(),

      (widget.userRole == 'SoftAdmin')
          ?
      AdminScreen(
        onThemeChanged: widget.onThemeChanged,
        currentTheme: widget.currentTheme,
        userRole: widget.userRole,
      ):
      DoctorAccount(
        onThemeChanged: widget.onThemeChanged,
        currentTheme: widget.currentTheme,
        userRole: widget.userRole,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0077BB),
        unselectedItemColor: Colors.grey,
        backgroundColor: isDark ? Color(0xff282828) : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}