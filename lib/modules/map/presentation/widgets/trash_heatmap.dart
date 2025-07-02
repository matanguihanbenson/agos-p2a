import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrashHeatmap extends StatefulWidget {
  const TrashHeatmap({super.key});

  @override
  State<TrashHeatmap> createState() => _TrashHeatmapState();
}

class _TrashHeatmapState extends State<TrashHeatmap> {
  final MapController _mapController = MapController();
  List<CircleMarker> _heatCircles = [];

  @override
  void initState() {
    super.initState();
    _loadTrashData();
  }

  Future<void> _loadTrashData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('detections')
        .orderBy('timestamp', descending: true)
        .limit(300)
        .get();

    final circles = snapshot.docs.map((doc) {
      final data = doc.data();
      final lat = data['location']['lat'];
      final lng = data['location']['lng'];
      final confidence = (data['confidence'] ?? 1.0) as num;

      final intensity = confidence.clamp(0.1, 1.0).toDouble();
      final color = getColorByIntensity(intensity);

      return CircleMarker(
        point: LatLng(lat.toDouble(), lng.toDouble()),
        color: color.withOpacity(0.6),
        radius: intensity * 40, // scale 0.1–1.0 to 4–40 px
        useRadiusInMeter: false,
      );
    }).toList();

    setState(() => _heatCircles = circles);
  }

  Color getColorByIntensity(double intensity) {
    if (intensity >= 0.9) return Colors.red;
    if (intensity >= 0.6) return Colors.orange;
    if (intensity >= 0.3) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(13.413, 121.180),
        initialZoom: 11,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        if (_heatCircles.isNotEmpty) CircleLayer(circles: _heatCircles),
      ],
    );
  }
}
