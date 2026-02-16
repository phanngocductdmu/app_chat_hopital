import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

Timer? _trackingTimer;
double? _lastLat;
double? _lastLng;

void startLocationTracking({
  required String userId,
  required String attendanceId,
}) {
  _trackingTimer?.cancel();

  _trackingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = pos.latitude;
      final lng = pos.longitude;

      // ⚠️ Nếu tọa độ giống với lần trước thì bỏ qua
      if (_lastLat != null &&
          _lastLng != null &&
          _isSameLocation(lat, lng, _lastLat!, _lastLng!)) {
        return;
      }

      // Cập nhật tọa độ mới
      _lastLat = lat;
      _lastLng = lng;

      final geoStr = '$lng,$lat'; // đúng định dạng yêu cầu

      final body = {
        'user_id': userId,
        'attendance_id': attendanceId,
        'geolocation': geoStr,
      };


      final response = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/tracking'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

    } catch (e) {
      print('❌ Lỗi khi gửi tracking: $e');
    }
  });
}

bool _isSameLocation(double lat1, double lng1, double lat2, double lng2, {double threshold = 0.00005}) {
  return (lat1 - lat2).abs() < threshold && (lng1 - lng2).abs() < threshold;
}
