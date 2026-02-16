import 'package:flutter/material.dart';
import 'image_preview_screen.dart';

class MediaGalleryScreen extends StatefulWidget {
  final List<dynamic> medias;
  final List<dynamic> links;
  final List<dynamic> files;

  const MediaGalleryScreen({
    super.key,
    required this.medias,
    required this.links,
    required this.files,
  });

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF0077BB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text('Kho Media',
            style: TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: [
              Tab(text: 'Ảnh'),
              Tab(text: 'Link'),
              Tab(text: 'File'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(widget.medias.isNotEmpty, _buildPhotosTab()),
          _buildTabContent(widget.links.isNotEmpty, _buildLinksTab()),
          _buildTabContent(widget.files.isNotEmpty, _buildFilesTab()),
        ],
      ),

    );
  }

  Widget _buildTabContent(bool hasData, Widget child) {
    return hasData
        ? child
        : Opacity(
      opacity: 0.3,
      child: IgnorePointer(child: child),
    );
  }

  /// Tab Ảnh
  Widget _buildPhotosTab() {
    Map<String, List<Map<String, dynamic>>> groupedByYear = {};

    for (var item in widget.medias) {
      String day = item['day'] ?? '';
      List mediasList = item['medias'] ?? [];
      DateTime? date;
      try {
        date = _parseDate(day);
      } catch (_) {
        continue;
      }

      String year = date.year.toString();
      groupedByYear.putIfAbsent(year, () => []);
      groupedByYear[year]!.add({
        'date': date,
        'dayString': day,
        'images': mediasList,
      });
    }

    var sortedYears = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (var year in sortedYears) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              year,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          for (var group in (groupedByYear[year]!..sort((a, b) {
            final dateA = a['date'];
            final dateB = b['date'];
            return dateB.compareTo(dateA);
          }))) ...[
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group['dayString'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: (group['images'] as List).length,
                      itemBuilder: (_, index) {
                        String? url = (group['images'] as List)[index];
                        bool isValid = url != null && url.isNotEmpty;
                        return GestureDetector(
                          onTap: isValid
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImagePreviewScreen(
                                  images: (group['images'] as List).cast<String>(),
                                  initialIndex: index,
                                ),
                              ),
                            );
                          }
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isValid
                                ? Image.network(url, fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade300),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// Tab Link
  Widget _buildLinksTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.links.length,
      itemBuilder: (context, index) {
        var dayItem = widget.links[index];
        String day = dayItem['day'] ?? '';
        List links = dayItem['links'] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
            const SizedBox(height: 6),
            ...links.map<Widget>((linkItem) {
              String? link = linkItem['link'];
              String title = linkItem['preview']?['title']?.isNotEmpty == true
                  ? linkItem['preview']['title']
                  : (link ?? '');
              String? image = linkItem['preview']?['image_src'];

              bool isValid = link != null && link.isNotEmpty;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: (image != null && image.isNotEmpty)
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(image, width: 40, height: 40, fit: BoxFit.cover))
                      : Icon(Icons.link, color: primaryColor),
                  title: Text(title,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(link ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: isValid ? () { /* TODO: open link */ } : null,
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// Tab File
  Widget _buildFilesTab() {
    return widget.files.isEmpty
        ? const Center(child: Text('Không có file'))
        : ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.files.length,
      itemBuilder: (_, index) {
        var file = widget.files[index];
        String? name = file['name'];
        String? url = file['url'];

        bool isValid = url != null && url.isNotEmpty;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(Icons.insert_drive_file, color: primaryColor),
            title: Text(name ?? 'File', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(url ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            onTap: isValid ? () { /* TODO: open file */ } : null,
          ),
        );
      },
    );
  }

  /// Parse dd-mm-yyyy to DateTime
  DateTime _parseDate(String day) {
    final parts = day.split('-');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }
}
