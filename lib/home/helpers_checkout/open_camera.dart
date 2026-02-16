import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:mime/mime.dart';
import 'dart:convert';

class CheckOutCameraScreen extends StatefulWidget {
  final String userId;

  const CheckOutCameraScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CheckOutCameraScreen> createState() => _CheckOutCameraScreenState();
}

class _CheckOutCameraScreenState extends State<CheckOutCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCheckOut();
  }

  Future<void> _startCheckOut() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa chụp ảnh check-out')),
        );
        Navigator.pop(context);
        return;
      }

      setState(() => _isLoading = true);

      final ip = await _getIpAddress();
      final location = await _getLocation();
      final locationStr = "${location['lat']},${location['lng']}";

      final bytes = await File(image.path).readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      final base64Image = 'data:$mimeType;base64,${base64Encode(bytes)}';

      final body = {
        'user_id': widget.userId,
        'checkout_ip': ip,
        'checkout_location': locationStr,
        'checkout_img': base64Image,
      };

      final response = await http.post(
        Uri.parse('https://account.nks.vn/api/nks/user/checkout'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      final data = jsonDecode(response.body);
      final success = data['success'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Check-out thành công!' : '❌ Check-out thất bại.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      Navigator.pop(context, {'success': success});
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi check-out: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final ip = jsonDecode(response.body)['ip'];
        return ip;
      } else {
      }
    } catch (e) {

    }
    return 'Unknown';
  }

  Future<Map<String, double>> _getLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return {'lat': position.latitude, 'lng': position.longitude};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHECK OUT'),
        backgroundColor: const Color(0xFF0077BB),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), // <-- title trắng
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Đang mở camera để check-out...'),
      ),
    );
  }
}