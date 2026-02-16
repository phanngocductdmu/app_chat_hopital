import 'package:flutter/material.dart';

class AvatarScreen extends StatelessWidget {
  final String avatarUrl;

  const AvatarScreen({
    super.key,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_sharp, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InteractiveViewer(
        child: Center(
          child: Image.network(
            avatarUrl,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                "Không thể hiển thị ảnh đại diện",
                style: TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0,),
        child: GestureDetector(
          onTap: () {

          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey),
            ),
            child: const Text(
              'Đổi ảnh đại diện',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
