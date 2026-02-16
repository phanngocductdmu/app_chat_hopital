import 'dart:io';
import 'package:app_chat_hospital/user/update/update_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_chat_hospital/pattern_login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme_mode_option.dart';
import '../theme_preferences.dart';
import 'update/update_avatar.dart';
import 'update/update_information_screen.dart';
import 'theme_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userRole;
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;
  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.userRole,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeModeOption _currentTheme;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final savedTheme = await ThemePreferences.loadTheme();
    setState(() {
      _currentTheme = savedTheme ?? widget.currentTheme;
    });
  }

  Future<void> _pickImageAndNavigateToCrop(BuildContext context) async {
    Permission permission = Platform.isIOS || Platform.version.contains('13') || Platform.version.contains('14')
        ? Permission.photos
        : Permission.storage;

    final status = await permission.request();
    if (status.isGranted) {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpdateAvatar(imageFile: File(pickedFile.path)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể truy cập thư viện ảnh nếu chưa cấp quyền.')),
        );
      }
    }
  }

  Future<void> _openThemeSelectionScreen() async {
    final selectedTheme = await Navigator.push<ThemeModeOption>(
      context,
      MaterialPageRoute(
        builder: (context) => ThemeSelectionScreen(
          currentTheme: _currentTheme,
          onThemeChanged: (newTheme) {
            widget.onThemeChanged(newTheme);
            setState(() => _currentTheme = newTheme);
            ThemePreferences.saveTheme(newTheme);
          },
        ),
      ),
    );

    if (selectedTheme != null && selectedTheme != _currentTheme) {
      setState(() => _currentTheme = selectedTheme);
      widget.onThemeChanged(selectedTheme);
      await ThemePreferences.saveTheme(selectedTheme);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : Colors.white;
    final primaryColor = const Color(0xFF0077BB);
    final dividerColor = isDark ? Colors.grey[700] : Colors.grey[300];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cài đặt', style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? Colors.black : primaryColor,
        elevation: 1,
      ),
      body: ListView(
        children: [
          _buildListItem(Icons.person_outline, 'Cập nhật thông tin', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UpdateInformation(
                  showBackButton: true,
                  userRole: widget.userRole,
                  onThemeChanged: widget.onThemeChanged,
                  currentTheme: widget.currentTheme,
                ),
              ),
            );
          }),

          _buildListItem(Icons.lock_outline, 'Thay đổi mật khẩu', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()));
          }),

          _buildListItem(Icons.photo_camera_outlined, 'Đổi ảnh đại diện', () {
            _pickImageAndNavigateToCrop(context);
          }),

          _buildListItem(Icons.notifications_none, 'Thông báo', () {}),

          _buildListItem(Icons.privacy_tip_outlined, 'Quyền riêng tư & bảo mật', () {}),

          _buildListItem(Icons.language, 'Ngôn ngữ', () {}),

          _buildListItem(Icons.color_lens_outlined, 'Giao diện', _openThemeSelectionScreen),

          _buildListItem(Icons.support_agent_outlined, 'Hỗ trợ & Liên hệ', () {}),

          _buildListItem(Icons.info_outline, 'Giới thiệu & Phiên bản', () {},
              trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey))),

          _buildListItem(Icons.logout, 'Đăng xuất', () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Xác nhận"),
                content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
                actions: [
                  TextButton(
                    child: const Text("Hủy", style: TextStyle(color: Colors.black)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(
                            onThemeChanged: widget.onThemeChanged,
                            currentTheme: _currentTheme,
                          ),
                        ),
                            (route) => false,
                      );
                    },
                  ),
                ],
              ),
            );
          }, iconColor: const Color(0xFFDD4A48)
          ),

        ],
      ),
    );
  }

  Widget _buildListItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        Widget? trailing,
        Color? iconColor,
      }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: (iconColor ?? const Color(0xFF0077BB)).withOpacity(0.1),
            child: Icon(icon, color: iconColor ?? const Color(0xFF0077BB)),
          ),
          title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.4),
      ],
    );
  }

}