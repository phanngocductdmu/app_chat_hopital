import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../password_generator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_onPasswordFieldsChanged);
    _newPasswordController.addListener(_onPasswordFieldsChanged);
    _confirmPasswordController.addListener(_onPasswordFieldsChanged);
  }

  void _onPasswordFieldsChanged() {
    setState(() {});
  }


  bool get _canSave =>
      _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text == _newPasswordController.text;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF0077BB)),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF0077BB)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF0077BB), width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _updatePasswordRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse('https://account.nks.vn/api/nks/user/updatePass'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'old_password': _currentPasswordController.text,
        'password': _newPasswordController.text,
        'access_token': accessToken,
      }),
    );

    if (response.statusCode == 200) {
      // Thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công!')),
      );
      Navigator.pop(context);
    } else {
      // Lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response.body}')),
      );
    }
  }

  void _updatePassword() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      _updatePasswordRequest().whenComplete(() => setState(() => _isLoading = false));
    }
  }


  void _goToGenerator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PasswordGeneratorScreen(
          onPasswordSelected: (generatedPassword) {
            setState(() {
              _newPasswordController.text = generatedPassword;
              _confirmPasswordController.text = generatedPassword;
            });
          },
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0077BB);
    final background = isDark ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu', style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? Colors.black : primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPasswordField(
                  label: "Mật khẩu hiện tại",
                  controller: _currentPasswordController,
                  obscure: _obscureCurrent,
                  icon: Icons.lock_outline,
                  toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  label: "Mật khẩu mới",
                  controller: _newPasswordController,
                  obscure: _obscureNew,
                  icon: Icons.lock_reset,
                  toggle: () => setState(() => _obscureNew = !_obscureNew),
                  extraIcon: IconButton(
                    icon: const Icon(Icons.lightbulb_outline, color: Color(0xFF0077BB)),
                    onPressed: _goToGenerator,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  label: "Xác nhận mật khẩu",
                  controller: _confirmPasswordController,
                  obscure: _obscureConfirm,
                  icon: Icons.verified_user_outlined,
                  toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSave && !_isLoading ? _updatePassword : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSave ? primaryColor : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _canSave ? 2 : 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Lưu', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required IconData icon,
    required VoidCallback toggle,
    Widget? extraIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF0077BB),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF0077BB)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (extraIcon != null) extraIcon,
            IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF0077BB),
              ),
              onPressed: toggle,
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),

        // Viền mặc định
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),

        // Viền khi focus
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0077BB), width: 2),
        ),

        // Viền khi có lỗi
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),

        // Viền khi focus nhưng có lỗi
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (value) {
        if (label.contains("hiện tại")) {
          return (value == null || value.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null;
        }
        if (label.contains("mới")) {
          if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
          if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
        }
        if (label.contains("Xác nhận")) {
          if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
          if (value != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
        }
        return null;
      },
    );

  }

}