import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userInfoUrl = 'https://account.nks.vn/api/nks/user';
  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  // Hàm lấy thông tin người dùng
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return null;
      }

      final response = await http.post(
        Uri.parse(_userInfoUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'access_token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          print('❌ Lấy thông tin thất bại: ${data['message']}');
        }
      } else {
        print('❌ Lỗi kết nối server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi khi gọi API lấy thông tin người dùng: $e');
    }
    return null;
  }
}
