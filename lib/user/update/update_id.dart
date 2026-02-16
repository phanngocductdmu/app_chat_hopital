import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'enter_id_info_screen.dart';

class UpdateIdScreen extends StatefulWidget {
  const UpdateIdScreen({super.key});

  @override
  State<UpdateIdScreen> createState() => _UpdateIdScreenState();
}

class _UpdateIdScreenState extends State<UpdateIdScreen> {
  File? _frontImage;
  File? _backImage;
  bool _isDisposed = false;
  bool _isLoading = false;

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(pickedFile.path);
        } else {
          _backImage = File(pickedFile.path);
        }
      });
    }
  }

  void _showImageSourceSheet(BuildContext context, bool isFront) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn ảnh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Chụp ảnh',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera(isFront);
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Bộ sưu tập',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(isFront);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(pickedFile.path);
        } else {
          _backImage = File(pickedFile.path);
        }
      });
    }
  }


  Future<Uint8List> convertToJpegIfNeeded(File file) async {
    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.path, headerBytes: bytes);
    if (mimeType == 'image/jpeg') {
      return bytes;
    }

    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) throw Exception("Không thể đọc ảnh");

    final jpegBytes = img.encodeJpg(decodedImage, quality: 85);
    return Uint8List.fromList(jpegBytes);
  }

  Future<String> convertFileToBase64WithPrefix(File file) async {
    final jpegBytes = await convertToJpegIfNeeded(file);
    final base64Data = base64Encode(jpegBytes);
    return 'data:image/jpeg;base64,$base64Data';
  }


  Future<Map<String, String>> scanCccdFromImage(File file) async {
    if (_isDisposed) return {}; // Nếu đã dispose, dừng lại

    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return {};

    image = img.grayscale(image);
    final processedPath = '${file.path}_bw.png';
    await File(processedPath).writeAsBytes(img.encodePng(image));

    final inputImage = InputImage.fromFilePath(processedPath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    if (_isDisposed) return {};

    final rawText = recognizedText.text;

    debugPrint("==== OCR RESULT FOR FILE: ${file.path} ====");
    debugPrint(rawText);

    final idNumber = RegExp(r'\b\d{12}\b').firstMatch(rawText)?.group(0) ?? '';
    final issueDate = RegExp(r'\b(\d{2}/\d{2}/\d{4})\b').firstMatch(rawText)?.group(0) ?? '';

    // Tách thành hàm riêng bên trong luôn
    String extractIssuePlace(String rawText) {
      final keywords = [
        'nơi cấp',
        'công an',
        'cục',
        'quản lý hành chính',
        'trật tự xã hội',
        'bộ công an',
      ];

      final lines = rawText.split('\n');
      final matchedLines = <String>[];

      for (final line in lines) {
        final lower = line.toLowerCase();
        if (keywords.any((keyword) => lower.contains(keyword))) {
          matchedLines.add(line.trim());
        }
      }

      return matchedLines.join(' ');
    }

    final issuePlace = extractIssuePlace(rawText);

    return {
      'id_number': idNumber,
      'issue_date': issueDate,
      'issue_place': issuePlace,
    };
  }



  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF0077BB);
    final isReadyToContinue = _frontImage != null && _backImage != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Cập nhật CCCD', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUploadBox("Upload ảnh mặt trước", _frontImage, () => _showImageSourceSheet(context, true), () => setState(() => _frontImage = null)),
                    const SizedBox(height: 20),
                    _buildUploadBox("Upload ảnh mặt sau", _backImage, () => _showImageSourceSheet(context, false), () => setState(() => _backImage = null)),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isReadyToContinue
                            ? () async {
                          setState(() => _isLoading = true);
                          try {
                            final frontBase64 = await convertFileToBase64WithPrefix(_frontImage!);
                            final backBase64 = await convertFileToBase64WithPrefix(_backImage!);

                            final ocrFront = await scanCccdFromImage(_frontImage!);
                            final ocrBack = await scanCccdFromImage(_backImage!);

                            final idNumber = ocrBack['id_number']!.isNotEmpty
                                ? ocrBack['id_number']!
                                : ocrFront['id_number']!;
                            final issueDate = ocrBack['issue_date']!.isNotEmpty
                                ? ocrBack['issue_date']!
                                : ocrFront['issue_date']!;
                            final issuePlace = ocrBack['issue_place']!.isNotEmpty
                                ? ocrBack['issue_place']!
                                : ocrFront['issue_place']!;

                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EnterIdInfoScreen(
                                    frontBase64: frontBase64,
                                    backBase64: backBase64,
                                    idNumber: idNumber,
                                    issueDate: issueDate,
                                    issuePlace: issuePlace,
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReadyToContinue ? backgroundColor : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Tiếp theo', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077BB)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadBox(String label, File? imageFile, VoidCallback onPick, VoidCallback onRemove) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 85.6 / 53.98,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : const Center(
                    child: Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              if (imageFile != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF0077BB),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
