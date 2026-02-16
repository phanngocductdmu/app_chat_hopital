import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/helpers_checkin/open_camera.dart';
import '../home/helpers_checkin/trackingTimer.dart';
import '../home/helpers_checkout/check_out.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_chat_hospital/notification_screen.dart';

class MainScreenDoctor extends StatefulWidget {
  const MainScreenDoctor({super.key});
  @override
  State<MainScreenDoctor> createState() => _MainScreenDoctorState();
}

class _MainScreenDoctorState extends State<MainScreenDoctor> {
  Timer? _timer;
  Timer? _trackingTimer;
  String _currentTime = '';
  Duration _duration = Duration.zero;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String id_user = '';
  String attendanceId = '';
  bool isCounting = false;
  bool isCheckingIn = false;
  bool _isLoading = true;
  String name = '';
  String avatar = '';
  String? checkInTime;
  String? checkOutTime;
  int _unreadCount = 0;

  final Color primaryColor = const Color(0xFF0077BB);

  @override
  void initState() {
    super.initState();
    _updateTime();
    _initApp();
    fetchUnreadNotificationCount().then((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  Future<void> _initApp() async {
    await _loadLocalState();
    if (!mounted) return;
    await _syncWithServer();
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    id_user = prefs.getInt('user_id')?.toString() ?? '';
    name = prefs.getString('user_name') ?? '';
    avatar = prefs.getString('user_avatar') ?? '';
    final cachedCheckIn = prefs.getString('check_in_time');

    if (cachedCheckIn != null) {
      final localCheckIn = DateTime.tryParse(cachedCheckIn);
      if (localCheckIn != null) {
        setState(() {
          isCounting = true;
          checkInTime = cachedCheckIn;
          _duration = DateTime.now().difference(localCheckIn);
          _isLoading = false;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _duration = DateTime.now().difference(localCheckIn);
          });
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWithServer() async {
    if (id_user.isEmpty) return;
    try {
      final result = await checkAttendanceToday(int.parse(id_user));
      final checkInStr = result['check_in'];
      final checkOutStr = result['check_out'];
      if (checkInStr != null) {
        final checkIn = DateTime.parse(checkInStr);
        if (checkOutStr == null) {
          setState(() {
            checkInTime = checkInStr;
            isCounting = true;
            _duration = DateTime.now().difference(checkIn);
          });

          _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            setState(() {
              _duration = DateTime.now().difference(checkIn);
            });
          });
        } else {
          final checkOut = DateTime.parse(checkOutStr);
          _timer?.cancel();
          setState(() {
            checkInTime = checkInStr;
            checkOutTime = checkOutStr;
            _duration = checkOut.difference(checkIn);
            isCounting = false;
          });
        }
      }
    } catch (e) {

    }
  }


  Future<Map<String, String?>> checkAttendanceToday(int userId) async {
    final now = DateTime.now();
    final String today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final response = await http.post(
      Uri.parse('https://account.nks.vn/api/nks/user/attendance'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'user_id': userId.toString(),
        'day': today,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'check_in': data['data']?['check_in'],
        'check_out': data['data']?['check_out'],
      };
    } else {
      throw Exception('Lỗi khi kiểm tra check-in');
    }
  }


  Future<void> _handleCheckIn() async {
    setState(() {
      isCheckingIn = true;
    });

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckInCameraScreen(userId: id_user),
      ),
    );

    if (result != null && result['success'] == true) {
      final attId = result['attendance_id'];
      final checkInTimeStr = result['created_at'];
      final parsedCheckIn = DateTime.tryParse(checkInTimeStr ?? '');

      if (parsedCheckIn != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_checked_in', true);
        await prefs.setString('check_in_time', parsedCheckIn.toIso8601String());
        await prefs.setString('attendance_id', attId.toString());

        setState(() {
          checkInTime = parsedCheckIn.toIso8601String();
          isCounting = true;
          _duration = DateTime.now().difference(parsedCheckIn);
          attendanceId = attId.toString();
          isCheckingIn = false;
        });

        startLocationTracking(userId: id_user, attendanceId: attId.toString());
      } else {
        setState(() {
          isCheckingIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi: Không lấy được thời gian check in từ máy chủ.")),
        );
      }
    } else {
      setState(() {
        isCheckingIn = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    final confirmed = await confirmAndStopTracking(context, id_user, _timer);
    if (confirmed) {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_checked_in', false);
      await prefs.remove('check_in_time');
      await prefs.remove('attendance_id');
      _timer?.cancel();
      if (checkInTime != null) {
        final checkIn = DateTime.parse(checkInTime!);
        setState(() {
          checkOutTime = now.toIso8601String();
          _duration = now.difference(checkIn);
          isCounting = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    return "$hours:$minutes";
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('H:mm').format(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _trackingTimer?.cancel();
    super.dispose();
  }

  String getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 11) {
      return 'Chào buổi sáng';
    } else if (hour >= 11 && hour < 13) {
      return 'Chào buổi trưa';
    } else if (hour >= 13 && hour < 18) {
      return 'Chào buổi chiều';
    } else {
      return 'Chào buổi tối';
    }
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


  Widget buildCard(String title, IconData icon) {
    return InkWell(
      onTap: () {

      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE9F5FF), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0077BB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0077BB), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('d/M/y', 'vi_VN').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Trang chủ', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Header: Avatar + Tên + Nút thông báo
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0077BB), Color(0xFF66B2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: avatar.isNotEmpty
                      ? ClipOval(child: Image.network(avatar, fit: BoxFit.cover))
                      : const Icon(Icons.person, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getGreeting(),
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                const Spacer(),
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

            const SizedBox(height: 20),

            /// Timer box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// Đồng hồ + ngày
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0077BB),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        today,
                        style: const TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                  const Spacer(),

                  /// Nút check in/out
                  Column(
                    children: [
                      SizedBox(
                        width: 170,
                        child: ElevatedButton.icon(
                          onPressed: isCounting || isCheckingIn || checkInTime != null
                              ? null
                              : _handleCheckIn,
                          icon: Icon(Icons.login, size: 20, color: isCounting ? Colors.white : Colors.grey),
                          label: Text(
                            checkInTime != null
                                ? "CHECK IN: ${DateFormat('HH:mm').format(DateTime.parse(checkInTime!))}"
                                : "CHECK IN",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCounting ? Colors.grey : primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 170,
                        child: ElevatedButton.icon(
                          onPressed: (checkInTime != null && checkOutTime == null)
                              ? _handleCheckOut
                              : null,
                          icon: const Icon(Icons.logout, size: 20),
                          label: Text(
                            checkOutTime != null
                                ? "CHECK OUT: ${DateFormat('HH:mm').format(DateTime.parse(checkOutTime!))}"
                                : "CHECK OUT",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (checkInTime != null && checkOutTime == null)
                                ? Colors.red
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            /// Các card chức năng
            buildCard('Hồ sơ bệnh án', Icons.folder_open),
            const SizedBox(height: 12),
            buildCard('Lịch khám bệnh', Icons.calendar_today),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
