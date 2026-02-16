import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EnterIdInfoScreen extends StatefulWidget {
  final String frontBase64;
  final String backBase64;
  final String? idNumber;
  final String? issueDate;
  final String? issuePlace;

  const EnterIdInfoScreen({
    super.key,
    required this.frontBase64,
    required this.backBase64,
    this.idNumber,
    this.issueDate,
    this.issuePlace,
  });

  @override
  State<EnterIdInfoScreen> createState() => _EnterIdInfoScreenState();
}

class _EnterIdInfoScreenState extends State<EnterIdInfoScreen> {
  late TextEditingController _idNumberController;
  late TextEditingController _issueDateController;
  late TextEditingController _issuePlaceController;

  final Color primaryColor = const Color(0xFF0077BB);
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();

    _idNumberController = TextEditingController(text: widget.idNumber ?? '');
    _issueDateController = TextEditingController(text: widget.issueDate ?? '');
    _issuePlaceController = TextEditingController(text: widget.issuePlace ?? '');

    _idNumberController.addListener(_validateForm);
    _issueDateController.addListener(_validateForm);
    _issuePlaceController.addListener(_validateForm);

    _validateForm();
  }

  void _validateForm() {
    final id = _idNumberController.text.trim();
    final date = _issueDateController.text.trim();
    final place = _issuePlaceController.text.trim();

    final isValid = id.length == 12 &&
        RegExp(r'^\d{12}$').hasMatch(id) &&
        date.isNotEmpty &&
        place.isNotEmpty;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<String?> pickImageAndConvertToBase64() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      return base64Encode(bytes);
    }
    return null;
  }

  void _submitCccd() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    // Parse ngày cấp từ dd/MM/yyyy -> yyyy-MM-dd
    String rawDate = _issueDateController.text.trim();
    String formattedDate = '';
    try {
      final parsedDate = DateFormat('dd/MM/yyyy').parse(rawDate);
      formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      print('❌ Lỗi định dạng ngày: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày cấp không hợp lệ')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://account.nks.vn/api/nks/user/updateCccd'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'front': widget.frontBase64,
        'back': widget.backBase64,
        'number': _idNumberController.text.trim(),
        'date': formattedDate,
        'place': _issuePlaceController.text.trim(),
        'access_token': accessToken,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('✅ Cập nhật CCCD thành công: $json');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật CCCD thành công!')),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      print('❌ Lỗi cập nhật CCCD: ${response.body}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response.body}')),
      );
    }
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    _issueDateController.dispose();
    _issuePlaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cập nhật CCCD',
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputField('Số Căn cước công dân', _idNumberController, isCCCD: true),
            const SizedBox(height: 16),
            _buildDatePickerField('Ngày cấp', _issueDateController),
            const SizedBox(height: 16),
            _buildInputField('Nơi cấp', _issuePlaceController),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid ? _submitCccd : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: primaryColor.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isCCCD = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isCCCD ? TextInputType.number : TextInputType.multiline,
          inputFormatters: isCCCD ? [FilteringTextInputFormatter.digitsOnly] : [],
          cursorColor: primaryColor,
          maxLines: isCCCD ? 1 : null,
          minLines: isCCCD ? 1 : 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: primaryColor.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1980),
              lastDate: DateTime.now(),
              helpText: 'Chọn ngày cấp',
              confirmText: 'Xong',
              cancelText: 'Hủy',
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              String formatted = '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
              controller.text = formatted;
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              cursorColor: primaryColor,
              decoration: InputDecoration(
                filled: true,
                fillColor: primaryColor.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                suffixIcon: Icon(Icons.calendar_today, color: primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}