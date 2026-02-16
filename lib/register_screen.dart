import 'dart:convert';
import 'dart:math';
import 'package:app_chat_hospital/theme_mode_option.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'authentication_screen.dart';

class RegisterScreen extends StatefulWidget {
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;

  const RegisterScreen({super.key, required this.currentTheme, required this.onThemeChanged});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("Vui lòng nhập đầy đủ thông tin.");
      return;
    }
    if (!email.contains('@')) {
      _showError("Email không hợp lệ.");
      return;
    }
    if (password.length < 6) {
      _showError("Mật khẩu phải có ít nhất 6 ký tự.");
      return;
    }
    if (password != confirmPassword) {
      _showError("Mật khẩu không khớp.");
      return;
    }
    setState(() {
      _isLoading = true;
    });
    // Tạo mã kích hoạt ngẫu nhiên 6 số
    final Code = (100000 + (Random().nextInt(900000))).toString();

    try {
      final response = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        final activationToken = data['activation_token'];
        final email = data['email'];

        // ✅ Lưu email và activation_token vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('activation_token', activationToken);
        await prefs.setString('email_token', email);

        print("✅ Mã key đã tạo: $activationToken");
        print("✅ Mã kích hoạt đã tạo: $Code");

        _showError("Đăng ký thành công. Vui lòng kiểm tra email để kích hoạt tài khoản.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AuthenticationScreen(
              activationCode: Code,
              currentTheme: widget.currentTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        );
      }
      else {
        final msg = responseData['message'];
        if (msg != null && msg is Map<String, dynamic>) {
          String errorMessages = '';

          if (msg.containsKey('name')) {
            final err = msg['name'][0];
            if (err.contains("already been taken")) {
              errorMessages += "Tên đã tồn tại.\n";
            } else if (err.contains("required")) {
              errorMessages += "Vui lòng nhập tên.\n";
            }
          }

          if (msg.containsKey('email')) {
            final err = msg['email'][0];
            if (err.contains("already been taken")) {
              errorMessages += "Email đã được sử dụng.\n";
            } else if (err.contains("valid email address")) {
              errorMessages += "Email không hợp lệ.\n";
            }
          }

          if (msg.containsKey('phone')) {
            final err = msg['phone'][0];
            if (err.contains("already been taken")) {
              errorMessages += "Số điện thoại đã được sử dụng.\n";
            } else if (err.contains("required")) {
              errorMessages += "Vui lòng nhập số điện thoại.\n";
            }
          }

          _showError(errorMessages.trim());
        } else {
          _showError("Đăng ký thất bại.");
        }

      }
    } catch (e) {
      _showError("Lỗi kết nối máy chủ.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      border: const UnderlineInputBorder(),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );

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
                      'Đăng ký tài khoản',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: inputDecoration.copyWith(hintText: 'Họ tên'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: inputDecoration.copyWith(hintText: 'Nhập email'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: inputDecoration.copyWith(hintText: 'Nhập số điện thoại'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: inputDecoration.copyWith(hintText: 'Nhập mật khẩu'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: inputDecoration.copyWith(hintText: 'Nhập lại mật khẩu'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D72B3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Đăng ký", style: TextStyle(color: Colors.white)),
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
                      Navigator.pop(context);
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
