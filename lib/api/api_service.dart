import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://account.nks.vn/api/nks/user/login";

  /// Gửi username + password → nhận phản hồi thành công
  static Future<Map<String, dynamic>?> checkLoginAndReturnToken(String username, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'access_token': data['data']['access_token'],
        'user': data['data']['user'],
      };
    } else {
      // In lỗi để debug
      print("❌ Đăng nhập thất bại");

      // Ném lỗi có chứa message từ API để xử lý bên ngoài
      throw Exception(data['message'] ?? 'Lỗi không xác định');
    }
  }


  /// Sau khi đăng nhập thành công, gọi hàm này để gửi thêm thông tin
  static Future<void> sendDeviceInfo({
    required String username,
    required String password,
    required String fbToken,
    required String ipAddress,
    required String deviceInfo,
    String system = "NKS",
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(baseUrl);

    final request = http.MultipartRequest('POST', url)
      ..fields['username'] = username
      ..fields['password'] = password
      ..fields['fbtoken'] = fbToken
      ..fields['system'] = system
      ..fields['device'] = deviceInfo
      ..fields['ip_address'] = ipAddress
      ..fields['location'] = '$latitude,$longitude';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("📤 Gửi thông tin thiết bị");
  }

}
