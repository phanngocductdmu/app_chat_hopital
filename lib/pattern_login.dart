import 'package:app_chat_hospital/home_screen.dart';
import 'package:app_chat_hospital/theme_mode_option.dart';
import 'package:app_chat_hospital/user/information_account_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'notification_screen.dart';
import 'forget_password.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_chat_hospital/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;

  const LoginScreen({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorText;
  List<Map<String, String>> _savedAccounts = [];
  String? _selectedAvatar;
  Map<String, dynamic>? selectedAccount;
  bool isKnownUser = false;
  int _unreadCount = 0;

  final inputDecoration = const InputDecoration(
    border: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
  );

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
    _initializeLoginScreen();
    fetchUnreadNotificationCount().then((count) {
      setState(() {
        _unreadCount = count;
      });
    });
  }

  Future<void> _initializeLoginScreen() async {
    await _loadSavedAccounts();
    if (_savedAccounts.isNotEmpty) {
      setState(() {
        selectedAccount = _savedAccounts.first;
        isKnownUser = true;
        _selectedAvatar = selectedAccount!['avatar'];
        _usernameController.text = selectedAccount!['username'] ?? '';
      });
    }
  }


  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('saved_accounts') ?? [];
    setState(() {
      _savedAccounts = saved.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    setState(() => _errorText = '');

    try {
      final loginResult = await ApiService.checkLoginAndReturnToken(username, password);
      if (loginResult != null) {
        final prefs = await SharedPreferences.getInstance();
        // Xóa tài khoản cũ
        await prefs.remove('saved_accounts');
        await prefs.remove('check_in_time');
        await prefs.remove('attendance_id');
        await prefs.clear();
        final userData = loginResult['user'];
        print('✅ Dữ liệu user trả về: $userData');
        final name = userData?['name'] ?? userData?['email'] ?? username;
        final avatar = userData?['avatar'] ?? '';
        final point = userData?['point'] ?? '0';
        final userId = userData?['id'] ?? 0;
        final firstname = userData?['firstname'] ?? '';
        final lastname = userData?['lastname'] ?? '';
        // Lưu token và thông tin người dùng
        await prefs.setString('access_token', loginResult['access_token']);
        await prefs.setString('user_name', name);
        await prefs.setString('user_avatar', avatar);
        await prefs.setString('user_point', point);
        await prefs.setInt('user_id', userId);
        await prefs.setString('user_firstname', firstname);
        await prefs.setString('user_lastname', lastname);
        // Lưu tài khoản vào danh sách
        await saveAccountToPrefs(username, name, avatar, firstname, lastname);
        // Gửi thông tin thiết bị
        final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
        print('fbtoken $fcmToken');
        final ip = await _getIpAddress();
        final deviceInfo = await _getDeviceModel();
        final location = await _getLocation();
        await ApiService.sendDeviceInfo(
          username: username,
          password: password,
          fbToken: fcmToken,
          ipAddress: ip,
          deviceInfo: deviceInfo,
          latitude: location['lat'] ?? 0.0,
          longitude: location['lng'] ?? 0.0,
        );

        final userRole = userData?['role']?['name'] ?? 'patient';

// 👉 Kiểm tra các trường null để xác định đăng nhập lần đầu
        final isFirstLogin = userData['firstname'] == null &&
            userData['lastname'] == null &&
            userData['dob'] == null &&
            userData['gender'] == null &&
            userData['id_number'] == null;

// 👉 Điều hướng tương ứng
        if (isFirstLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InformationScreen(
                userRole: userRole,
                showBackButton: false,
                currentTheme: widget.currentTheme,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userRole: userRole,
                currentTheme: widget.currentTheme,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        }
      } else {
        setState(() => _errorText = 'Sai tên đăng nhập hoặc mật khẩu');
      }
    } catch (e) {
      final message = e.toString();
      if (message.contains('Activation')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tài khoản chưa kích hoạt'),
            content: const Text('Tài khoản của bạn chưa được kích hoạt. Vui lòng liên hệ quản trị viên để được hỗ trợ.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () {
                  _activateAccount(context);
                },
                child: const Text('Kích hoạt', style: TextStyle(color: Color(0xFF0077BB))),
              )
            ],
          ),
        );
      } else if (message.contains('Unauthorized')) {
        setState(() => _errorText = 'Sai tên đăng nhập hoặc mật khẩu.');
      } else {
        // setState(() => _errorText = 'Đăng nhập thất bại: $message');
        setState(() => _errorText = 'Đăng nhập thất bại');
      }
      print('❌ Lỗi đăng nhập: $message');
    }
  }

  Future<void> _activateAccount(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('activation_token');
    final email = prefs.getString('email_token');

    if (token == null || email == null) {
      _showDialog(context, 'Thiếu thông tin kích hoạt. Vui lòng đăng ký lại.');
      return;
    }

    final url = Uri.parse('https://account.nks.vn/api/nks/user/activation/$token');

    try {
      final response = await http.get(url);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          responseData['success'] == true &&
          responseData['data'] == 'Active successful') {
        _showDialog(context, '🎉 Kích hoạt tài khoản thành công! Bạn có thể đăng nhập.');
      } else {
        _showDialog(context, '❌ Kích hoạt thất bại. Vui lòng kiểm tra lại liên kết hoặc thông tin.');
      }
    } catch (e) {
      _showDialog(context, '⚠️ Đã xảy ra lỗi: $e');
    }
  }

  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Future.delayed(Duration(milliseconds: 100), () {
                Navigator.of(context).pop();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> saveAccountToPrefs(String username, String name, String avatar, String firstname, String lastname) async {
    final prefs = await SharedPreferences.getInstance();

    final newAccount = jsonEncode({
      'username': username,
      'name': name,
      'avatar': avatar,
      'firstname': firstname,
      'lastname': lastname,
    });

    List<String> savedAccounts = prefs.getStringList('saved_accounts') ?? [];

    savedAccounts.removeWhere((acc) {
      final map = jsonDecode(acc);
      return map['username'] == username;
    });

    savedAccounts.insert(0, newAccount);

    await prefs.setStringList('saved_accounts', savedAccounts);
    print("✅ Danh sách sau khi lưu: $savedAccounts");
  }

  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) return jsonDecode(response.body)['ip'];
    } catch (_) {}
    return 'Unknown';
  }

  Future<String> _getDeviceModel() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.model ?? 'Unknown';
    } catch (_) {}
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
      }
    } catch (_) {}
    return {'lat': 0.0, 'lng': 0.0};
  }

  void _onAccountSelected(Map<String, String> account) {
    setState(() {
      _usernameController.text = account['username'] ?? '';
      _selectedAvatar = account['avatar'];
      selectedAccount = account;
      isKnownUser = true;
    });
  }

  Future<int> fetchUnreadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) return 0;

    final response = await http.post(
      Uri.parse('https://account.nks.vn/api/nks/notifications'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'user_id': userId.toString()},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final notifications = data['data'] as List;
      return notifications.where((n) => n['read_at'] == null).length;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedAccount = _savedAccounts.firstWhere(
          (acc) => acc['username'] == _usernameController.text,
      orElse: () => {},
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 10,
        elevation: 0,
        backgroundColor: isDark ? Colors.black : Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Container(
            color: isDark ? Colors.black : Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/nks_logo.png',
                        height: 40,
                        color: isDark ? Colors.white : null,
                        colorBlendMode: isDark ? BlendMode.modulate : null,
                      ),
                      const Spacer(),
                      Icon(Icons.qr_code, size: 28, color: Color(0xFF0077bb)),
                      const SizedBox(width: 16),
                      Icon(Icons.card_giftcard, size: 28, color: Color(0xFF0077bb)),
                      const SizedBox(width: 5),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none, size: 28, color: Color(0xFF0077BB)),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationScreen()),
                              );
                              if (result == true) {
                                final count = await fetchUnreadNotificationCount();
                                setState(() {
                                  _unreadCount = count;
                                });
                              }
                            },
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                child: Center(
                                  child: Text(
                                    '$_unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isKnownUser)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 38),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_selectedAvatar != null) ...[
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(_selectedAvatar!),
                                    radius: 40,
                                  ),
                                ],
                                const SizedBox(width: 30),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Xin Chào", style: TextStyle(fontSize: 18)),
                                    Text(
                                      ((selectedAccount['name'] ?? selectedAccount['user_name']) ?? '...').toString().toUpperCase(),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const Text("Chúc một ngày làm việc hiệu quả", style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Icon(Icons.lock, color: Color(0xff0077bb)),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      cursorColor: isDark ? Colors.white : Colors.black,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Mật khẩu',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      color: Color(0xff0077bb),
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_errorText != null) ...[
                              Text(_errorText!, style: const TextStyle(color: Colors.red)),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D72B3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text("Đăng nhập", style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        isKnownUser = false;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0077BB)),
                                    label: const Text(
                                      "Đăng nhập tài khoản khác",
                                      style: TextStyle(color: Color(0xFF0077BB)),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));
                                  },
                                  child: const Text("Quên mật khẩu", style: TextStyle(color: Color(0xFF0077BB))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 38),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Đăng nhập', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Color(0xFF2D72B3))),
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
                                border: Border.all(color: isDark ? Colors.white24 : Colors.black38),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, color: Color(0xFF0077bb)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              controller: _usernameController,
                                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                              decoration: inputDecoration.copyWith(
                                                hintText: 'Tên đăng nhập',
                                                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(color: isDark ? Colors.white24 : Colors.black26),
                                  Row(
                                    children: [
                                      const Icon(Icons.lock_outline, color: Color(0xFF0077bb)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                          decoration: inputDecoration.copyWith(
                                            hintText: 'Mật khẩu',
                                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF0077bb)),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_errorText != null)
                                    Text(_errorText!, style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2D72B3),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          child: const Text("OK", style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.all(10),
                                        ),
                                        child: const Icon(Icons.grid_4x4, color: Color(0xFF0077bb)),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));
                                      },
                                      child: const Text("Quên mật khẩu", style: TextStyle(color: Colors.blue)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Bạn chưa có tài khoản. ", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                currentTheme: widget.currentTheme,
                                onThemeChanged: widget.onThemeChanged,
                              ),
                            ),
                          );
                        },
                        child: const Text("Đăng ký", style: TextStyle(color: Color(0xFF2D72B3))),
                      ),
                    ],
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

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.message, [this.details]);

  @override
  String toString() => 'ApiException: $message';
}
