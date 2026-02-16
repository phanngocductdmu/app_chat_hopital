import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:mime/mime.dart';

Future<String> _getIpAddress() async {
  try {
    final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
    if (response.statusCode == 200) {
      final ip = jsonDecode(response.body)['ip'];
      return ip;
    } else {
      print('❌ Không lấy được IP, mã: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Lỗi khi lấy IP: $e');
  }
  return 'Unknown';
}

Future<Map<String, double>> _getLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      final pos = await Geolocator.getCurrentPosition();
      return {'lat': pos.latitude, 'lng': pos.longitude};
    } else {
      print('❌ Quyền định vị bị từ chối: $permission');
    }
  } catch (e) {
    print('❌ Lỗi khi lấy vị trí: $e');
  }
  return {'lat': 0.0, 'lng': 0.0};
}

/// ✅ Hàm checkin mới: Trả về Map<String, dynamic>? nếu thành công, null nếu lỗi
Future<Map<String, dynamic>?> checkInUser({
  required String userId,
  required File checkinImage,
  required int late,
  required int half,
}) async {
  final ip = await _getIpAddress();
  final location = await _getLocation();
  final locationStr = '${location['lat']},${location['lng']}';

  final url = Uri.parse('https://account.nks.vn/api/nks/user/checkin');

  final bytes = await checkinImage.readAsBytes();
  final mimeType = lookupMimeType(checkinImage.path) ?? 'image/png';
  final base64Image = 'data:$mimeType;base64,${base64Encode(bytes)}';

  final body = {
    'user_id': userId,
    'checkin_ip': ip,
    'checkin_location': locationStr,
    'checkin_img': base64Image,
    'late': late.toString(),
    'half': half.toString(),
  };

  body.forEach((key, value) {
    if (value == null || value.toString().trim().isEmpty) {

    } else {
      final preview = value.toString().length > 100
          ? '${value.toString().substring(0, 100)}...'
          : value.toString();

    }
  });

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );


    if (!response.body.trim().startsWith('{')) {

      return null;
    }

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data; // TRẢ VỀ TOÀN BỘ JSON
    } else {
      return null;
    }
  } catch (e) {
    print('❌ Exception khi gửi checkin: $e');
    return null;
  }
}
