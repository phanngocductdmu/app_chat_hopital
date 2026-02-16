import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreviewScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late PageController _pageController;
  late ScrollController _thumbScrollController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    _thumbScrollController = ScrollController();

    // Scroll để ảnh đầu tiên vào giữa (nếu cần)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerThumbnail(currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScrollController.dispose();
    super.dispose();
  }

  void _centerThumbnail(int index) {
    final itemWidth = 60 + 8; // width + margin
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (index * itemWidth) - (screenWidth / 2 - itemWidth / 2);
    _thumbScrollController.animateTo(
      offset.clamp(0, _thumbScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Ảnh lớn
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
                _centerThumbnail(index);
              },
              itemBuilder: (context, index) {
                final imgUrl = widget.images[index];
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(imgUrl),
                  ),
                );
              },
            ),
          ),
          // Dãy danh sách ảnh nhỏ
          SizedBox(
            height: 80,
            child: ListView.builder(
              controller: _thumbScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final thumbUrl = widget.images[index];
                final isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(index);
                    _centerThumbnail(index);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Opacity(
                      opacity: isSelected ? 1.0 : 0.4, // mờ đi
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          thumbUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
