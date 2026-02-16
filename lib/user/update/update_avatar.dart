import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateAvatar extends StatefulWidget {
  final File imageFile;

  const UpdateAvatar({super.key, required this.imageFile});

  @override
  State<UpdateAvatar> createState() => _UpdateAvatarState();
}

class _UpdateAvatarState extends State<UpdateAvatar> {
  final CropController _cropController = CropController();

  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageFile.readAsBytesSync();
  }

  String encodeImageToBase64WithMime(Uint8List bytes) {
    final mimeType = lookupMimeType('', headerBytes: bytes) ?? 'image/jpeg';
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  void _saveAndPop(Uint8List croppedData) async {
    // 1. Mã hóa ảnh với đúng MIME
    String base64Image = encodeImageToBase64WithMime(croppedData);

    print(base64Image);

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    // 2. Gửi API cập nhật avatar
    final response = await http.post(
      Uri.parse('https://account.nks.vn/api/nks/user/updateAvatar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'avatar': base64Image,
        'access_token': accessToken,
      }),
    );

    // 3. Kiểm tra phản hồi
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('📥 Response từ updateAvatar: $json');

      await prefs.setString('user_avatar', base64Image);
      print('✅ Avatar base64 đã lưu vào SharedPreferences');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu thành công!')),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response.body}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_imageBytes == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Chỉnh sửa ảnh đại diện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _cropController.crop();
            },
          ),
        ],
      ),
      body: Center(
        child: Crop(
          controller: _cropController,
          image: _imageBytes!,
          withCircleUi: true,
          interactive: true,
          baseColor: Colors.black,
          maskColor: Colors.black.withOpacity(0.5),
          onCropped: (croppedData) {
            _saveAndPop(croppedData);
          },
        ),
      ),
    );
  }
}