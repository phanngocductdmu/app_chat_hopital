import 'package:app_chat_hospital/theme_mode_option.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pattern_login.dart';

class OnboardingScreen extends StatefulWidget {
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;
  const OnboardingScreen({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  List<Map<String, String>> onboardingData = [
    {
      'title': 'Chào mừng đến với ứng dụng',
      'desc': 'Ứng dụng giúp bạn trò chuyện với bệnh nhân dễ dàng.',
    },
    {
      'title': 'Quản lý nhanh chóng',
      'desc': 'Quản lý thông tin và lịch sử bệnh nhân hiệu quả.',
    },
    {
      'title': 'Bắt đầu ngay',
      'desc': 'Hãy đăng nhập và trải nghiệm ngay!',
    },
  ];

  void _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);
    } catch (e) {
      debugPrint('❗ Lỗi khi lưu onboarding_seen: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    ThemeMode currentMode;
    switch (widget.currentTheme) {
      case ThemeModeOption.light:
        currentMode = ThemeMode.light;
        break;
      case ThemeModeOption.dark:
        currentMode = ThemeMode.dark;
        break;
      case ThemeModeOption.system:
      default:
        currentMode = ThemeMode.system;
    }

    final brightness = currentMode == ThemeMode.system
        ? MediaQuery.of(context).platformBrightness
        : (currentMode == ThemeMode.dark ? Brightness.dark : Brightness.light);

    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: onboardingData.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      onboardingData[index]['title']!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      onboardingData[index]['desc']!,
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Visibility(
              visible: currentIndex != onboardingData.length - 1,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  "Bỏ qua",
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    onboardingData.length,
                        (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentIndex == index ? 12 : 8,
                      height: currentIndex == index ? 12 : 8,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? const Color(0xFF0077BB)
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077BB),
                  ),
                  onPressed: currentIndex == onboardingData.length - 1
                      ? _finishOnboarding
                      : () {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                  child: Text(
                    currentIndex == onboardingData.length - 1 ? 'Bắt đầu' : 'Tiếp theo',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

}
