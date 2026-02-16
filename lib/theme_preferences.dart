import 'package:shared_preferences/shared_preferences.dart';
import 'theme_mode_option.dart';

class ThemePreferences {
  static const _key = 'theme_mode';

  static Future<void> saveTheme(ThemeModeOption theme) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_key, theme.index);
  }

  static Future<ThemeModeOption?> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key)) return null;
    int index = prefs.getInt(_key) ?? 0;
    return ThemeModeOption.values[index];
  }
}
