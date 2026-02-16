import 'package:flutter/material.dart';
import 'dart:async';

class MainScreenPatient extends StatefulWidget {
  const MainScreenPatient({super.key});

  @override
  State<MainScreenPatient> createState() => _MainScreenPatientState();
}

class _MainScreenPatientState extends State<MainScreenPatient> {
  final Color primaryColor = const Color(0xFF0077BB);
  final String linkUrl = "https://tamduchearthospital.com/wp-content/uploads/2025/05/banner-Thong-bao-Phong-chong-dich-benh.webp";

  Timer? _timer;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < doctors.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  final List<Map<String, String>> doctors = [
    {
      "name": "Trần Thị Cúc",
      "degree": "Thạc sĩ - Bệnh viện Quân Y 175",
      "specialty": "Truyền nhiễm - Viêm gan"
    },
    {
      "name": "Nguyễn Văn An",
      "degree": "Tiến sĩ - Bệnh viện Chợ Rẫy",
      "specialty": "Tim mạch"
    },
    {
      "name": "Lê Thị Hoa",
      "degree": "Bác sĩ chuyên khoa II - Bệnh viện 108",
      "specialty": "Thần kinh"
    },
    {
      "name": "Phạm Minh Tuấn",
      "degree": "Thạc sĩ - Bệnh viện Đại học Y Hà Nội",
      "specialty": "Nhi khoa"
    },
    {
      "name": "Ngô Thị Mai",
      "degree": "Bác sĩ chuyên khoa I - Bệnh viện Bạch Mai",
      "specialty": "Hô hấp"
    },
    {
      "name": "Hoàng Văn Dũng",
      "degree": "Tiến sĩ - Bệnh viện Việt Đức",
      "specialty": "Chỉnh hình"
    },
    {
      "name": "Đặng Thị Lan",
      "degree": "Thạc sĩ - Bệnh viện Nhi Trung Ương",
      "specialty": "Nhi khoa"
    },
  ];


  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? Color(0xff121212) : primaryColor,
        title: const Text('Trang chủ', style: TextStyle(color: Colors.white)),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text.rich(
                  TextSpan(
                    text: 'Xin chào, ',
                    style: const TextStyle(fontSize: 18),
                    children: [
                      TextSpan(
                        text: 'Phan Ngoc Duc',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 4),
                child: SizedBox(
                  height: 40, // Chiều cao nhỏ lại
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      hintText: 'Bạn đang tìm gì ...',
                      hintStyle: TextStyle(color: primaryColor),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    cursorColor: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Bạn đang muốn khám bệnh gì',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return CircleAvatar(
                      radius: 25,
                      backgroundColor: primaryColor,
                      child: const Icon(Icons.local_hospital, color: Colors.white),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Kết nối bác sĩ chuyên khoa đầu ngành',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 180,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: doctors.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade300,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                      image: const DecorationImage(
                                        image: AssetImage('assets/images/nks_logo.png'),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    child: const Icon(Icons.person, size: 36, color: Colors.white),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          doctor["name"] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          doctor["degree"] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doctor["specialty"] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Xử lý nhấn chat bác sĩ
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(12),
                                      backgroundColor: Colors.blue.shade700,
                                    ),
                                    child: const Icon(Icons.chat_outlined, color: Colors.white, size: 24),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(doctors.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          width: _currentPage == index ? 12 : 8,
                          height: _currentPage == index ? 12 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? primaryColor : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cẩm nang sức khỏe',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Xem tất cả >', style: TextStyle(color: primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3 / 2,
                  physics: const NeverScrollableScrollPhysics(), // tắt scroll riêng
                  shrinkWrap: true, // cho GridView tự co chiều cao theo nội dung
                  children: List.generate(12, (index) {
                    return Column(
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.network(
                            linkUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Icon(Icons.broken_image));
                            },
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text('Tin tức ${index + 1}'),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
