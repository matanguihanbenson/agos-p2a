import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class BotTrackingMap extends StatefulWidget {
  const BotTrackingMap({super.key});

  @override
  State<BotTrackingMap> createState() => _BotTrackingMapState();
}

class _BotTrackingMapState extends State<BotTrackingMap> {
  final DatabaseReference _botsRef = FirebaseDatabase.instance.ref('bots');
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  Map<String, LatLng> _botLocations = {};
  Map<String, Map<String, dynamic>> _botDetails = {};
  String? _selectedBotId;
  LatLng? _selectedBotPosition;
  StreamSubscription<DatabaseEvent>? _sub;
  bool _showBotList = false;

  @override
  void initState() {
    super.initState();
    _listenToRealtimebots();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenToRealtimebots() {
    // Use onValue with a more aggressive listener for real-time updates
    _sub = _botsRef.onValue.listen(
      (event) {
        final botsData = event.snapshot.value as Map<dynamic, dynamic>?;

        if (botsData == null) {
          print('No bot data found.');
          if (mounted) {
            setState(() {
              _botLocations.clear();
              _botDetails.clear();
              _selectedBotId = null;
              _selectedBotPosition = null;
            });
          }
          return;
        }

        final updatedLocations = <String, LatLng>{};
        final updatedDetails = <String, Map<String, dynamic>>{};

        botsData.forEach((key, value) {
          if (value is Map) {
            final lat = value['lat'];
            final lng = value['lng'];

            if (lat != null && lng != null) {
              final latDouble = (lat as num).toDouble();
              final lngDouble = (lng as num).toDouble();
              updatedLocations[key.toString()] = LatLng(latDouble, lngDouble);
              updatedDetails[key.toString()] = {
                'name': value['name'] ?? 'Bot $key',
                'status': value['status'] ?? 'unknown',
                'active': value['active'] ?? false,
                'battery': value['battery'] ?? 0,
                'speed': value['speed'] ?? 0.0,
                'lastUpdate': DateTime.now().millisecondsSinceEpoch,
              };
              print('✅ Bot $key → lat: $latDouble, lng: $lngDouble');
            } else {
              print('⚠️ Bot $key has missing lat/lng');
            }
          }
        });

        print('🛰 Final updatedLocations: $updatedLocations');

        if (mounted) {
          setState(() {
            _botLocations = updatedLocations;
            _botDetails = updatedDetails;

            // Only auto-select first bot if none is selected and locations exist
            if (_botLocations.isNotEmpty && _selectedBotId == null) {
              final first = _botLocations.entries.first;
              _selectedBotId = first.key;
              _selectedBotPosition = first.value;
              _mapController.move(first.value, 14);
            } else if (_selectedBotId != null &&
                !_botLocations.containsKey(_selectedBotId)) {
              // If selected bot is no longer available, clear selection
              _selectedBotId = null;
              _selectedBotPosition = null;
            } else if (_selectedBotId != null &&
                _botLocations.containsKey(_selectedBotId!)) {
              // Update selected bot position if it exists
              _selectedBotPosition = _botLocations[_selectedBotId!];
            }
          });
        }
      },
      onError: (error) {
        print('❌ Error listening to bot data: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error connecting to bot data: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
    );
  }

  void _onBotTap(String botId, LatLng position) {
    setState(() {
      _selectedBotId = botId;
      _selectedBotPosition = position;
    });

    final botDetail = _botDetails[botId];
    if (botDetail == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildBotDetailSheet(botId, position, botDetail),
    );
  }

  Widget _buildBotDetailSheet(
    String botId,
    LatLng position,
    Map<String, dynamic> details,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_boat_rounded,
                  color: colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details['name'],
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: $botId',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: details['active']
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE57373),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  details['active'] ? 'ACTIVE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Details
          _buildDetailCard([
            _buildInfoRow(
              Icons.location_on_rounded,
              'Position',
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
            ),
            _buildInfoRow(
              Icons.info_outline_rounded,
              'Status',
              details['status'].toString().toUpperCase(),
            ),
            _buildInfoRow(
              Icons.battery_full_rounded,
              'Battery',
              '${details['battery']}%',
            ),
            _buildInfoRow(
              Icons.speed_rounded,
              'Speed',
              '${details['speed']} knots',
            ),
          ], colorScheme),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mapController.move(position, 16);
                  },
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Follow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mapController.move(position, _mapController.camera.zoom);
                  },
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  label: const Text('Center'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.add_rounded,
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.remove_rounded,
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
      ),
    );
  }

  void _recenterToNearestBot() {
    if (_botLocations.isEmpty) return;

    final currentCenter = _mapController.camera.center;

    String? nearestId;
    double minDistance = double.infinity;

    _botLocations.forEach((id, position) {
      final dist = _distance(currentCenter, position);
      if (dist < minDistance) {
        minDistance = dist;
        nearestId = id;
      }
    });

    if (nearestId != null) {
      final nearestPosition = _botLocations[nearestId]!;
      _mapController.move(nearestPosition, _mapController.camera.zoom);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Recentered to nearest bot: $nearestId"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final markers = _botLocations.entries.map((entry) {
      final botId = entry.key;
      final position = entry.value;
      final details = _botDetails[botId];
      final isSelected = _selectedBotId == botId;
      final isActive = details?['active'] == true;

      return Marker(
        point: position,
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        child: GestureDetector(
          onTap: () => _onBotTap(botId, position),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                    : [const Color(0xFFE57373), const Color(0xFFD32F2F)],
              ),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_boat_rounded,
              size: isSelected ? 24 : 20,
              color: Colors.white,
            ),
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(13.413, 121.180),
            initialZoom: 12,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(top: 16, left: 16, child: _buildControlPanel()),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'recenter',
            onPressed: _recenterToNearestBot,
            label: const Text('Recenter'),
            icon: const Icon(Icons.center_focus_strong_rounded),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Bot counter badge
        if (_botLocations.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_boat_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_botLocations.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
