import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'location_info_card.dart';
import 'modern_info_row.dart';

class LocationTab extends StatefulWidget {
  final Map<String, dynamic>? realtime;
  final Map<String, dynamic> data;

  const LocationTab({Key? key, this.realtime, required this.data})
    : super(key: key);

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  List<double>? _geocodedBoundingBox;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final realtimeLocation =
        widget.realtime?['location'] as Map<String, dynamic>?;
    final firestoreLocation = widget.data['location'] as Map<String, dynamic>?;

    final directLat = widget.realtime?['lat'] ?? widget.data['lat'];
    final directLng = widget.realtime?['lng'] ?? widget.data['lng'];

    final zone = widget.data['zone']?.toString();
    final depth =
        widget.realtime?['depth']?.toString() ??
        widget.data['depth']?.toString();
    final lastSeen = widget.realtime?['last_seen'] ?? widget.data['last_seen'];

    // Get coordinates for map
    final lat =
        (realtimeLocation?['lat'] ?? firestoreLocation?['lat'] ?? directLat)
            ?.toDouble();
    final lng =
        (realtimeLocation?['lng'] ?? firestoreLocation?['lng'] ?? directLng)
            ?.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lat != null && lng != null) ...[
            // Map Section
            Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.agos.app',
                    ),
                    // Bounding box layer (check multiple sources)
                    if (widget.realtime?['boundingbox'] != null)
                      _buildBoundingBoxLayer(
                        widget.realtime!['boundingbox'],
                        cs,
                      )
                    else if (widget.data['boundingbox'] != null)
                      _buildBoundingBoxLayer(widget.data['boundingbox'], cs)
                    else if (_geocodedBoundingBox != null)
                      _buildBoundingBoxLayer(_geocodedBoundingBox!, cs),
                    // Boat marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.directions_boat,
                              color: cs.onPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Location Info Card
            LocationInfoCard(
              lat: lat,
              lng: lng,
              accuracy:
                  (realtimeLocation?['accuracy'] ??
                          firestoreLocation?['accuracy'])
                      ?.toString(),
              cs: cs,
              onBoundingBoxChanged: (boundingBox) {
                if (mounted) {
                  setState(() {
                    _geocodedBoundingBox = boundingBox;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          if (zone != null) ...[
            ModernInfoRow(Icons.place, 'Zone', zone, cs),
            const SizedBox(height: 8),
          ],
          if (depth != null) ...[
            ModernInfoRow(Icons.water, 'Depth', '$depth m', cs),
            const SizedBox(height: 8),
          ],
          if (lastSeen != null) ...[
            ModernInfoRow(
              Icons.schedule,
              'Last Seen',
              lastSeen is Timestamp
                  ? _fmtFirestore(lastSeen)
                  : _fmtRealtime(lastSeen),
              cs,
            ),
          ],
          if (realtimeLocation == null &&
              firestoreLocation == null &&
              directLat == null &&
              directLng == null &&
              zone == null &&
              depth == null &&
              lastSeen == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'No location information available',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoundingBoxLayer(dynamic boundingBox, ColorScheme cs) {
    if (boundingBox is! List || boundingBox.length != 4) {
      return const SizedBox();
    }

    try {
      // boundingbox format: [south, north, west, east]
      final south = double.parse(boundingBox[0].toString());
      final north = double.parse(boundingBox[1].toString());
      final west = double.parse(boundingBox[2].toString());
      final east = double.parse(boundingBox[3].toString());

      if (kDebugMode) {
        print('Drawing bounding box: S:$south, N:$north, W:$west, E:$east');
      }

      // Create rectangle polygon points
      final bounds = [
        LatLng(south, west), // Southwest corner
        LatLng(south, east), // Southeast corner
        LatLng(north, east), // Northeast corner
        LatLng(north, west), // Northwest corner
        LatLng(south, west), // Close the polygon
      ];

      return PolygonLayer(
        polygons: [
          Polygon(
            points: bounds,
            color: cs.primary.withOpacity(0.15),
            borderColor: cs.primary.withOpacity(0.7),
            borderStrokeWidth: 2,
            isFilled: true,
          ),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing bounding box: $e');
      }
      return const SizedBox();
    }
  }

  String _fmtRealtime(dynamic ts) {
    try {
      final dt = ts is int
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.parse(ts as String);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'N/A';
    }
  }

  String _fmtFirestore(Timestamp t) {
    final dt = t.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
