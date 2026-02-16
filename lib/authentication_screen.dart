import 'package:app_chat_hospital/theme_mode_option.dart';
import 'package:flutter/material.dart';
import 'pattern_login.dart';

class AuthenticationScreen extends StatefulWidget {
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;
  final String activationCode;

  const AuthenticationScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.activationCode,
  });

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final int otpLength = 6;
  late List<TextEditingController> otpControllers;
  late List<FocusNode> otpFocusNodes;

  @override
  void initState() {
    super.initState();
    otpControllers = List.generate(otpLength, (index) => TextEditingController());
    otpFocusNodes = List.generate(otpLength, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Widget buildOTPFields() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(otpLength, (index) {
        return Container(
          width: 45,
          height: 55,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: otpControllers[index],
            focusNode: otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              fillColor: isDark ? Colors.grey[900] : Colors.white,
              filled: true,
            ),
            onChanged: (value) {
              if (value.length == 1 && index < otpLength - 1) {
                otpFocusNodes[index].unfocus();
                FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                otpFocusNodes[index].unfocus();
                FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
              }
            },
          ),
        );
      }),
    );
  }

  void _verifyCode() {
    final enteredCode = otpControllers.map((e) => e.text).join();
    if (enteredCode == widget.activationCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Kích hoạt thành công!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            currentTheme: widget.currentTheme,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Mã không đúng, vui lòng thử lại.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Image.network(
                'https://nks.com.vn/wp-content/uploads/2023/05/nks-full-logo-1024x539.png',
                height: 40,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                      'Kích hoạt tài khoản',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildOTPFields(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D72B3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gửi lại mật khẩu',
                      style: TextStyle(
                        color: Color(0xFF1717bf),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Bạn đã có tài khoản. "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(
                            currentTheme: widget.currentTheme,
                            onThemeChanged: widget.onThemeChanged,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Đăng nhập ngay",
                      style: TextStyle(color: Color(0xFF2D72B3)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}