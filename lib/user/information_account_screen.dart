import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:app_chat_hospital/user/avatar_screen.dart';
import 'package:app_chat_hospital/user/update/update_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/user_service.dart';
import '../models/user_info.dart';
import '../theme_mode_option.dart';
import 'update/update_information_screen.dart';
import 'update/update_id.dart';

class InformationScreen extends StatefulWidget {
  final bool showBackButton;
  final String userRole;
  final ThemeModeOption currentTheme;
  final Function(ThemeModeOption) onThemeChanged;

  const InformationScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.userRole,
    required this.showBackButton,
  });

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  late Future<UserInfo?> _userInfoFuture;
  Future<Map<int, String>>? _provinceMapFuture;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = _fetchUserInfo();
  }

  Future<UserInfo?> _fetchUserInfo() async {
    final data = await UserService.getUserInfo();
    if (data != null) {
      return UserInfo.fromJson(data);
    }
    return null;
  }

  void _refreshUserInfo() {
    setState(() {
      _userInfoFuture = _fetchUserInfo();
    });
  }

  Future<Map<int, String>> fetchProvinces(int countryId) async {
    final uri = Uri.https(
      'online.nks.vn',
      '/api/nks/provinces',
      {
        'country_id': countryId.toString(),
        'sclBox': 'true',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List provinces = data['data'];
      final responseData = jsonDecode(response.body);
      final newAvatar = responseData['data']['avatar'] ?? "";
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar', newAvatar);
      if (mounted) Navigator.pop(context, true);

      return {for (var p in provinces) p['id']: p['title']};
    } else {
      throw Exception('Failed to load provinces');
    }
  }

  void _showAvatarOptions(BuildContext context, String? avatarUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Xem ảnh đại diện"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AvatarScreen(avatarUrl: avatarUrl ?? ''),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Đổi ảnh đại diện"),
              onTap: () {
                Navigator.pop(context);
                _pickImageAndNavigateToCrop(context, fromBottomSheet: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageAndNavigateToCrop(BuildContext context, {bool fromBottomSheet = false}) async {
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
                'Đổi ảnh đại diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Chụp ảnh',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromCamera(context);
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Bộ sưu tập',
                    onTap: () async {
                      Navigator.pop(context);
                      await _openGalleryAndCrop(context, fromBottomSheet);
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

  Future<void> _pickFromCamera(BuildContext context) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => UpdateAvatar(imageFile: imageFile),
        ),
      );
      _refreshUserInfo();
    }
  }

  Future<void> _openGalleryAndCrop(BuildContext context, bool fromBottomSheet) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => UpdateAvatar(imageFile: imageFile),
        ),
      );
      _refreshUserInfo();
    }
    if (fromBottomSheet && context.mounted) {
      Navigator.pop(context);
    }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1c1c1e) : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        )
            : null,
        title: const Text('Thông tin cá nhân', style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? Colors.black : const Color(0xFF0077BB),
        actions: [
          FutureBuilder<UserInfo?>(
            future: _userInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateInformation(
                          userRole: widget.userRole,
                          showBackButton: widget.showBackButton,
                          currentTheme: widget.currentTheme,
                          onThemeChanged: widget.onThemeChanged,
                        ),
                      ),
                    );
                    _refreshUserInfo();
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<UserInfo?>(
        future: _userInfoFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0077BB)));
          } else if (userSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Đã xảy ra lỗi:\n${userSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text('Không có dữ liệu người dùng.'));
          }

          final user = userSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showAvatarOptions(context, user.avatar),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: const Color(0xFF0077BB),
                            backgroundImage: user.avatar?.isNotEmpty == true ? NetworkImage(user.avatar!) : null,
                            child: user.avatar == null || user.avatar!.isEmpty
                                ? const Icon(Icons.person, size: 55, color: Colors.white)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _pickImageAndNavigateToCrop(context),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0077BB),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name ?? 'Chưa rõ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0077BB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.point ?? 0} điểm',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._buildProfileDetails(user),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildProfileDetails(UserInfo user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Divider(color: isDark ? Colors.grey[700] : Colors.grey[200], thickness: 0.5);

    final List<Map<String, dynamic>> allDetails = [
      {'icon': Icons.vpn_key, 'title': 'Code', 'value': user.code},
      {'icon': Icons.person, 'title': 'Họ và tên', 'value': '${user.firstname} ${user.lastname}'},
      {'custom': true},
      {'icon': Icons.phone, 'title': 'Số điện thoại', 'value': user.phone},
      {'icon': Icons.male, 'title': 'Giới tính', 'value': user.gender == 1 ? 'Nam' : 'Nữ'},
      {'icon': Icons.cake, 'title': 'Ngày sinh', 'value': user.formattedDob},
      {'icon': Icons.flag, 'title': 'Nơi sinh', 'value': user.pob},
      {'icon': Icons.home, 'title': 'Địa chỉ tạm trú', 'value': user.province},
    ];

    final widgets = <Widget>[];

    for (int i = 0; i < allDetails.length; i++) {
      final detail = allDetails[i];

      if (i != 0) {
        widgets.add(divider); // Thêm Divider từ phần tử thứ 2 trở đi
      }

      if (detail['custom'] == true) {
        widgets.add(_buildCccdTile(user));
      } else {
        widgets.add(ProfileTile(
          icon: detail['icon'],
          title: detail['title'],
          value: detail['value'] ?? '-',
        ));
      }
    }

    return widgets;
  }

  Widget _buildCccdTile(UserInfo user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nền bo tròn cho icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0077BB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.badge, color: Color(0xFF0077BB), size: 20),
          ),
          const SizedBox(width: 15),

          // Nội dung CCCD
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CCCD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${user.idNumber ?? '-'} - ${user.formattedIdDate ?? '-'} - ${user.idPlace ?? '-'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          // Nút sửa
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Color(0xFF0077BB)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateIdScreen()));
            },
          ),
        ],
      ),
    );
  }

}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onEdit;

  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon với nền tròn nhẹ
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0077BB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0077BB), size: 20),
          ),

          const SizedBox(width: 16),

          // Title + Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    )),
              ],
            ),
          ),

          // Nút chỉnh sửa nếu có
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
              onPressed: onEdit,
              tooltip: 'Chỉnh sửa',
            ),
        ],
      ),
    );
  }
}
