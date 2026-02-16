import 'package:flutter/material.dart';

class MemberInfoPage extends StatelessWidget {
  const MemberInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0077BB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin thành viên'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar + Info
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryColor,
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Như Trần',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Bệnh nhân',
                        style: TextStyle(color: primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Điểm tích lũy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Điểm tích luỹ đến ngày 1/6/2025'),
                  SizedBox(height: 6),
                  Text(
                    '6.688 điểm',
                    style: TextStyle(
                      fontSize: 28,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('6.688 điểm hết hạn vào ngày 31/12/2025'),
                  SizedBox(height: 8),
                  Text(
                    'Lịch sử tích điểm',
                    style: TextStyle(color: primaryColor, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Ưu đãi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: const [
                  Text(
                    'Ưu đãi của bạn',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.card_giftcard, color: Colors.white),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
