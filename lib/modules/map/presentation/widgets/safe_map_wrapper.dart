import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SafeMapWrapper extends StatefulWidget {
  final Widget Function(MapController controller) builder;
  final LatLng initialCenter;
  final double initialZoom;

  const SafeMapWrapper({
    super.key,
    required this.builder,
    this.initialCenter = const LatLng(13.4024, 122.5632),
    this.initialZoom = 13,
  });

  @override
  State<SafeMapWrapper> createState() => _SafeMapWrapperState();
}

class _SafeMapWrapperState extends State<SafeMapWrapper> {
  late final MapController _mapController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Mark map as ready after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isMapReady = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMapReady) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing map...'),
          ],
        ),
      );
    }

    return widget.builder(_mapController);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
