import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddLeaveScreen extends StatefulWidget {
  const AddLeaveScreen({super.key});

  @override
  State<AddLeaveScreen> createState() => _AddLeaveScreenState();
}

class _AddLeaveScreenState extends State<AddLeaveScreen> {
  final _fullnameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHalfDay = false;

  int? _selectedTypeId;
  List<Map<String, dynamic>> _leaveTypes = [];

  final Color themeColor = const Color(0xFF0077BB);

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
    _loadDefaultFullname();
  }

  Future<void> _loadLeaveTypes() async {
    final url = Uri.parse('https://account.nks.vn/api/nks/leavetypes');

    try {
      final response = await http.post(url, headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];

        setState(() {
          _leaveTypes = data.map<Map<String, dynamic>>((e) {
            return {
              'id': e['id'],
              'title': e['title'] ?? '',
            };
          }).toList();
        });
      } else {
        debugPrint('Lỗi khi lấy loại nghỉ phép: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi API loại nghỉ phép: $e');
    }
  }

  Future<void> _loadDefaultFullname() async {
    final prefs = await SharedPreferences.getInstance();
    String firstname = prefs.getString('user_firstname') ?? '';
    String lastname = prefs.getString('user_lastname') ?? '';

    final savedName = firstname + ' ' + lastname;
    setState(() {
      _fullnameController.text = savedName;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: themeColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_startDate == null ||
        _reasonController.text.trim().isEmpty ||
        _selectedTypeId == null ||
        _fullnameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final url = Uri.parse('https://account.nks.vn/api/nks/leave/create');
    final body = {
      'user_id': userId.toString(),
      'begin_at': DateFormat('yyyy-MM-dd').format(_startDate!),
      'reason': _reasonController.text.trim(),
      'type': _selectedTypeId.toString(),
      'halfday': _isHalfDay ? '1' : '',
      'fullname': _fullnameController.text.trim(),
    };

    if (!_isHalfDay && _endDate != null) {
      body['end_at'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi đơn thất bại')),
      );
    }
  }

  Widget _buildCardField({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: themeColor);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text("Xin nghỉ phép"),
        foregroundColor: Colors.white,
        backgroundColor: themeColor,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardField(
              child: TextField(
                controller: _fullnameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  labelStyle: textStyle,
                  border: InputBorder.none,
                ),
              ),
            ),
            _buildCardField(
              child: TextField(
                controller: _startDateController,
                readOnly: true,
                onTap: () => _pickDate(isStart: true),
                decoration: InputDecoration(
                  labelText: 'Ngày bắt đầu',
                  labelStyle: textStyle,
                  border: InputBorder.none,
                ),
              ),
            ),
            _buildCardField(
              child: TextField(
                controller: _endDateController,
                readOnly: true,
                enabled: !_isHalfDay,
                onTap: _isHalfDay ? null : () => _pickDate(isStart: false),
                decoration: InputDecoration(
                  labelText: 'Ngày kết thúc',
                  labelStyle: textStyle,
                  hintText: _isHalfDay ? 'Bỏ qua khi nghỉ nửa ngày' : '',
                  border: InputBorder.none,
                ),
              ),
            ),
            _buildCardField(
              child: TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Lý do nghỉ phép',
                  labelStyle: textStyle,
                  border: InputBorder.none,
                ),
              ),
            ),
            _buildCardField(
              child: DropdownButtonFormField<int>(
                value: _selectedTypeId,
                items: _leaveTypes.map((type) {
                  return DropdownMenuItem<int>(
                    value: type['id'] as int,
                    child: Text(type['title']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedTypeId = value),
                decoration: InputDecoration(
                  labelText: 'Loại nghỉ phép',
                  labelStyle: textStyle,
                  border: InputBorder.none,
                ),
              ),
            ),
            CheckboxListTile(
              value: _isHalfDay,
              onChanged: (value) => setState(() {
                _isHalfDay = value ?? false;
                if (_isHalfDay) {
                  _endDate = null;
                  _endDateController.clear();
                }
              }),
              title: Text('Nghỉ nửa ngày', style: textStyle),
              activeColor: themeColor,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitLeaveRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Gửi đơn xin nghỉ',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
