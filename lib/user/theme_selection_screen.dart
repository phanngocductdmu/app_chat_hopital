import 'package:flutter/material.dart';
import 'package:app_chat_hospital/theme_mode_option.dart';
import 'package:app_chat_hospital/theme_preferences.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;

  const ThemeSelectionScreen({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _ThemeSelectionScreenState createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  late ThemeModeOption _selectedTheme;
  final Color primaryColor = const Color(0xFF0077BB);

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
  }

  void _onThemeChanged(ThemeModeOption newTheme) async {
    setState(() {
      _selectedTheme = newTheme;
    });
    widget.onThemeChanged(newTheme);
    await ThemePreferences.saveTheme(newTheme);
  }

  Widget _buildThemeOption({
    required ThemeModeOption value,
    required String title,
    required IconData icon,
    required Color textColor,
  }) {
    final isSelected = _selectedTheme == value;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: RadioListTile<ThemeModeOption>(
        value: value,
        groupValue: _selectedTheme,
        activeColor: primaryColor,
        onChanged: (val) {
          if (val != null) _onThemeChanged(val);
        },
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
            color: isSelected ? primaryColor : textColor,
          ),
        ),
        secondary: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.grey[600],
          size: 28,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final isDarkAppbar = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chọn giao diện',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
        backgroundColor: isDarkAppbar ? Colors.black : const Color(0xFF0077BB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios), // đổi icon nút back
          color: Colors.white, // màu icon nút back
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          _buildThemeOption(
            value: ThemeModeOption.system,
            title: 'Theo hệ thống',
            icon: Icons.settings,
            textColor: textColor,
          ),
          _buildThemeOption(
            value: ThemeModeOption.light,
            title: 'Sáng',
            icon: Icons.wb_sunny_outlined,
            textColor: textColor,
          ),
          _buildThemeOption(
            value: ThemeModeOption.dark,
            title: 'Tối',
            icon: Icons.nights_stay_outlined,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}
