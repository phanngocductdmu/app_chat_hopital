import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/user_service.dart';
import '../../home_screen.dart';
import '../../models/user_info.dart';
import '../../theme_mode_option.dart';

class UpdateInformation extends StatefulWidget {
  final bool showBackButton;
  final String userRole;
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;

  const UpdateInformation({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.showBackButton,
    required this.userRole,
  });

  @override
  State<UpdateInformation> createState() => _UpdateInformationState();
}

class _UpdateInformationState extends State<UpdateInformation> {
  late Future<UserInfo?> _userInfoFuture;
  Map<String, String> _originalValues = {};
  int? provinceId;
  final FocusNode nameFocusNode = FocusNode();
  bool _isChanged = false;
  String selectedGender = '';
  List<Map<String, dynamic>>? _provinces;


  final Map<String, TextEditingController> _controllers = {
    'firstname': TextEditingController(),
    'lastname': TextEditingController(),
    'birth': TextEditingController(),
    'phone': TextEditingController(),
    'place': TextEditingController(),
    'cccd': TextEditingController(),
    'idDate': TextEditingController(),
    'idPlace': TextEditingController(),
    'street': TextEditingController(),
    'streetNumber': TextEditingController(),
    'ward': TextEditingController(),
    'district': TextEditingController(),
    'province': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    nameFocusNode.addListener(() {
      if (!nameFocusNode.hasFocus) {
        setState(() {});
      }
    });
    _userInfoFuture = _fetchUserInfo();
    _loadUserInfo();
    _loadProvinces();
  }

  Future<UserInfo?> _fetchUserInfo() async {
    final data = await UserService.getUserInfo();
    if (data != null) return UserInfo.fromJson(data);
    return null;
  }

  String _toIsoDate(String input) {
    try {
      final parsed = DateFormat('dd/MM/yyyy').parseStrict(input);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (e) {
      return '';
    }
  }

  void _checkIfChanged() {
    bool changed = false;
    _originalValues.forEach((key, value) {
      if (key == 'gender') {
        if (selectedGender != value) changed = true;
      } else if (_controllers[key]?.text != value) {
        changed = true;
      }
    });

    setState(() {
      _isChanged = changed;
    });
  }

  void _loadUserInfo() async {
    final userInfo = await _fetchUserInfo();
    if (userInfo != null) {
      setState(() {
        _controllers['firstname']!.text = userInfo.firstname ?? '';
        _controllers['lastname']!.text = userInfo.lastname ?? '';
        _controllers['birth']!.text = userInfo.formattedDob ?? '';
        _controllers['phone']!.text = userInfo.phone ?? '';
        _controllers['place']!.text = userInfo.pob ?? '';
        _controllers['cccd']!.text = userInfo.idNumber ?? '';
        _controllers['idDate']!.text = userInfo.formattedIdDate ?? '';
        _controllers['idPlace']!.text = userInfo.idPlace ?? '';
        _controllers['street']!.text = userInfo.addStreet ?? '';
        _controllers['streetNumber']!.text = '';
        _controllers['ward']!.text = userInfo.addWard ?? '';
        _controllers['district']!.text = userInfo.addDistrict ?? '';
        _controllers['province']!.text = userInfo.province ?? '';
        selectedGender = userInfo.gender == 1
            ? 'Nam'
            : userInfo.gender == 2
            ? 'Nữ'
            : '';
        _originalValues = {
          'firstname': _controllers['firstname']!.text,
          'lastname': _controllers['lastname']!.text,
          'birth': _controllers['birth']!.text,
          'phone': _controllers['phone']!.text,
          'place': _controllers['place']!.text,
          'cccd': _controllers['cccd']!.text,
          'idDate': _controllers['idDate']!.text,
          'idPlace': _controllers['idPlace']!.text,
          'street': _controllers['street']!.text,
          'streetNumber': _controllers['streetNumber']!.text,
          'ward': _controllers['ward']!.text,
          'district': _controllers['district']!.text,
          'province': _controllers['province']!.text,
          'gender': selectedGender,
        };

        _isChanged = false;
      });
      _controllers.forEach((key, controller) {
        controller.removeListener(_checkIfChanged);
        controller.addListener(_checkIfChanged);
      });
    }
  }

  Future<void> _updateUserInfo() async {
    final phone = _controllers['phone']?.text ?? '';
    if (!isValidPhoneNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Số điện thoại không hợp lệ. Phải bắt đầu bằng số 0 và có đúng 10 chữ số.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final firstname = _controllers['firstname']?.text ?? '';
    final lastname = _controllers['lastname']?.text ?? '';
    final dob = _toIsoDate(_controllers['birth']?.text ?? '');
    final idDate = _toIsoDate(_controllers['idDate']?.text ?? '');

    final uri = Uri.parse('https://account.nks.vn/api/nks/user/updateInfo');
    final request = http.MultipartRequest('POST', uri)
      ..fields['access_token'] = accessToken ?? ''
      ..fields['firstname'] = firstname
      ..fields['lastname'] = lastname
      ..fields['phone'] = phone
      ..fields['gender'] = selectedGender == 'Nam' ? '1' : (selectedGender == 'Nữ' ? '2' : '')
      ..fields['dob'] = dob
      ..fields['pob'] = _controllers['place']?.text ?? ''
      ..fields['id_number'] = _controllers['cccd']?.text ?? ''
      ..fields['id_date'] = idDate
      ..fields['id_place'] = _controllers['idPlace']?.text ?? ''
      ..fields['province'] = (provinceId ?? 79).toString()
      ..fields['intro'] = 'ko co gi';

    final response = await request.send();

    if (!mounted) return;

    if (response.statusCode == 200) {
      final resString = await response.stream.bytesToString();
      final json = jsonDecode(resString);
      if (json['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cập nhật thành công!")),
        );
        if (widget.showBackButton == true) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userRole: widget.userRole,
                currentTheme: widget.currentTheme,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi mạng khi cập nhật thông tin.")),
      );
    }
  }

  bool isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^0\d{9}$');
    return regex.hasMatch(phone);
  }

  bool isValidIdNumber(String idNumber) {
    final regex = RegExp(r'^\d{12}$');
    return regex.hasMatch(idNumber);
  }

  void _handleBackButton() async {
    if (_isChanged) {
      final confirm = await _showConfirmDialog(
        title: 'Xác nhận',
        content: 'Bạn có chắc chắn muốn thoát không? Mọi thay đổi chưa lưu sẽ bị mất.',
        confirmText: 'Thoát',
        cancelText: 'Hủy',
        confirmColor: Colors.red,
      );
      if (confirm == true) Navigator.of(context).pop(true);
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _loadProvinces() async {
    if (_provinces == null) {
      _provinces = await fetchProvinces();
      setState(() {});
    }
  }





  Future<List<Map<String, dynamic>>> fetchProvinces() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final response = await http.post(
      Uri.parse('https://online.nks.vn/api/nks/provinces?country_id=192&slcBox=true'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map<Map<String, dynamic>>((item) => {
        'id': item['id'],
        'title': item['title'],
      }).toList();
    } else {
      throw Exception('Lỗi khi lấy danh sách tỉnh');
    }
  }

  Widget _buildProvincePicker() {
    return InkWell(
      onTap: () async {
        final provinces = await fetchProvinces();
        final selected = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            TextEditingController searchController = TextEditingController();
            List<Map<String, dynamic>> filtered = provinces;
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 5,
                        width: 50,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      TextField(
                        controller: searchController,
                        cursorColor: Color(0xFF0077BB),
                        decoration: InputDecoration(
                          hintText: 'Tìm tỉnh/thành phố...',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF0077BB)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFF0077BB), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filtered = provinces
                                .where((item) => item['title']
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 300,
                        child: filtered.isEmpty
                            ? Center(child: Text("Không tìm thấy"))
                            : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final province = filtered[index];
                            return ListTile(
                              title: Text(province['title']),
                              onTap: () => Navigator.pop(context, province),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );

        if (selected != null) {
          setState(() {
            _controllers['province']!.text = selected['title'];
            _isChanged = true;
            provinceId = selected['id'];
          });
        }
      },
      child: IgnorePointer(
        child: _buildTextField(label: 'Tỉnh/Thành phố', keyName: 'province'),
      ),
    );
  }

  void _updateUserData() async {
    final confirm = await _showConfirmDialog(
      title: 'Xác nhận cập nhật',
      content: 'Bạn có chắc chắn muốn cập nhật thông tin không?',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      confirmColor: Colors.red,
    );
    if (confirm == true) {
      await _updateUserInfo();
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
    Color? confirmColor,
    Color? cancelColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          content,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: TextStyle(color: cancelColor ?? (isDark ? Colors.grey[300] : Colors.grey[800])),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(color: confirmColor ?? Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    nameFocusNode.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required String keyName,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    void Function()? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controllers[keyName],
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelText: label,
          labelStyle: TextStyle(
            color: const Color(0xFF0077BB),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        cursorColor: const Color(0xFF0077BB),
        onChanged: (_) => _checkIfChanged(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFFdfe3e6),
      appBar: AppBar(
        title: const Text('Cập nhật thông tin', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: isDark ? Colors.black : const Color(0xFF0077BB),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 27),
          onPressed: _handleBackButton,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(label: 'Họ và tên lót', keyName: 'firstname'),
                _buildTextField(label: 'Tên', keyName: 'lastname'),
                _buildTextField(
                  label: 'Ngày sinh',
                  keyName: 'birth',
                  readOnly: true,
                  onTap: () async {
                    final today = DateTime.now();
                    final lastDate = DateTime(today.year - 20, today.month, today.day);
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: lastDate,
                      firstDate: DateTime(1900),
                      lastDate: lastDate,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: const Color(0xFF0077BB),
                              onPrimary: Colors.white,
                              onSurface: const Color(0xFF0077BB),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      _controllers['birth']!.text = DateFormat('dd/MM/yyyy').format(picked);
                      setState(() => _isChanged = true);
                    }
                  },
                ),
                const SizedBox(height: 12),

                Text('Giới tính', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0077BB))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Nam',
                      groupValue: selectedGender,
                      activeColor: const Color(0xFF0077BB),
                      onChanged: (val) {
                        setState(() {
                          selectedGender = val!;
                          _isChanged = true;
                        });
                      },
                    ),
                    const Text('Nam'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'Nữ',
                      groupValue: selectedGender,
                      activeColor: const Color(0xFF0077BB),
                      onChanged: (val) {
                        setState(() {
                          selectedGender = val!;
                          _isChanged = true;
                        });
                      },
                    ),
                    const Text('Nữ'),
                  ],
                ),
                const SizedBox(height: 12),

                _buildTextField(label: 'Số điện thoại', keyName: 'phone', keyboardType: TextInputType.phone),
                _buildTextField(label: 'Nơi sinh', keyName: 'place'),
                _buildTextField(label: 'Số nhà', keyName: 'streetNumber'),
                _buildTextField(label: 'Tên đường', keyName: 'street'),
                _buildTextField(label: 'Phường/Xã', keyName: 'ward'),
                _buildTextField(label: 'Quận/Huyện', keyName: 'district'),
                _buildProvincePicker(),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChanged ? _updateUserData : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isChanged ? const Color(0xFF0077BB) : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: _isChanged ? 2 : 0,
                    ),
                    child: const Text('Lưu', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}