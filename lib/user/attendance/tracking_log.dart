import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class TrackingLog extends StatefulWidget {
  final DateTime date;

  const TrackingLog({super.key, required this.date});

  @override
  State<TrackingLog> createState() => _TrackingLogState();
}

class _TrackingLogState extends State<TrackingLog> {
  String _selectedUser = '92 - BS0001';
  late final MapController _mapController;
  List<LatLng> _polylinePoints = [];

  final Map<String, int> _userIds = {
    '92 - BS0001': 92,
    '116 - BS0003': 116,
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    final userId = _userIds[_selectedUser]!;
    final date = widget.date;
    final url = Uri.parse('https://account.nks.vn/api/nks/user/trackinglogs');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'user_id': userId.toString(),
        'day': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['data']['geojson']['features'][0]['geometry']['coordinates'];

      setState(() {
        _polylinePoints = coords.map<LatLng>((point) {
          return LatLng(point[1], point[0]);
        }).toList();

        if (_polylinePoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(_polylinePoints);
          _mapController.fitBounds(
            bounds,
            options: const FitBoundsOptions(
              padding: EdgeInsets.all(5), // CÀNG NHỎ CÀNG GẦN
              maxZoom: 19.5, // zoom tối đa cho gần hơn
            ),
          );
        }
      });
    }
  }

  void _onUserChanged(String username) {
    setState(() {
      _selectedUser = username;
    });
    _loadTrackingData();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF0077BB);
    final formattedDate = '${widget.date.day.toString().padLeft(2, '0')}/'
        '${widget.date.month.toString().padLeft(2, '0')}/'
        '${widget.date.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              value: _selectedUser,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: themeColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: themeColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: themeColor),
              style: TextStyle(color: themeColor, fontSize: 16),
              items: _userIds.keys.map((user) {
                return DropdownMenuItem<String>(
                  value: user,
                  child: Text(user),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _onUserChanged(value);
              },
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: LatLng(10.76, 106.7), // fallback center
                  zoom: 15,
                  maxZoom: 25,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=ZSxwnmKEyVRHxO66jqqP',
                    userAgentPackageName: 'com.example.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _polylinePoints,
                        color: Colors.red,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
