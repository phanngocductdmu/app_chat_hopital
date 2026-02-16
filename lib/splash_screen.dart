import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_mode_option.dart';
import 'onboarding_screen.dart';
import 'pattern_login.dart';

class SplashScreen extends StatefulWidget {
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;

  const SplashScreen({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Chờ 2 giây hiển thị logo
    await Future.delayed(const Duration(seconds: 2));

    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('onboarding_seen') ?? false;

      if (mounted) {
        if (seen) {
          // Đã xem onboarding → vào login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                currentTheme: widget.currentTheme,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        } else {
          // Chưa xem → vào onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingScreen(
                currentTheme: widget.currentTheme,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Nếu lỗi, fallback vào Login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              currentTheme: widget.currentTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/nks_logo.png',
          width: 150,
        ),
      ),
    );
  }
}
