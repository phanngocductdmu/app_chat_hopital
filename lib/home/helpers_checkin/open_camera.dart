import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'check_in.dart';

class CheckInCameraScreen extends StatefulWidget {
  final String userId;

  const CheckInCameraScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CheckInCameraScreen> createState() => _CheckInCameraScreenState();
}

class _CheckInCameraScreenState extends State<CheckInCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final now = DateTime.now();
  int late = 0;
  int half = 0;




  Future<void> _startCheckIn() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa chụp ảnh check-in')),
        );
        Navigator.pop(context);
        return;
      }

      setState(() => _isLoading = true);

      if (now.isAfter(DateTime(now.year, now.month, now.day, 9, 0))) {
        late = 1;
      }

      if (now.isAfter(DateTime(now.year, now.month, now.day, 13, 30))) {
        half = 1;
      }

      final result = await checkInUser(
        userId: widget.userId,
        checkinImage: File(image.path),
        late: late,
        half: half,
      );

      setState(() => _isLoading = false);

      if (result != null) {
        final id = result['data']['id'].toString();
        final createdAt = result['data']['created_at'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-in thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, {
          'success': true,
          'attendance_id': id,
          'created_at': createdAt,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Check-in thất bại.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi check-in: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _startCheckIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHECK IN'),
        backgroundColor: const Color(0xFF0077BB),
        iconTheme: const IconThemeData(color: Colors.white), // <-- icon trắng
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), // <-- title trắng
        actionsIconTheme: const IconThemeData(color: Colors.white), // <-- nếu có actions
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Đang mở camera để check-in...'),
      ),
    );
  }
}
