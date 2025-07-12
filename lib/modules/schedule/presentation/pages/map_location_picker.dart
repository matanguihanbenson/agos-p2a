import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/geocoding_service.dart';

class MapLocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final int coverageRadius;
  final String title;
  final bool showCoverageCircle;

  const MapLocationPicker({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.coverageRadius,
    required this.title,
    this.showCoverageCircle = true,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late double _selectedLatitude;
  late double _selectedLongitude;
  late int _currentRadius;
  late MapController _mapController;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _selectedLocationAddress;
  bool _isGeocodingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _currentRadius = widget.coverageRadius;
    _mapController = MapController();

    // Get initial address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLocationAddress();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await LocationService.instance.getCurrentLocation(
        forceRefresh: true,
      );

      if (position != null) {
        setState(() {
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _selectedLocationAddress = null; // Clear previous address
        });

        // Move map to current location
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );

        // Update address for new location
        _updateLocationAddress();

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location updated with ${position.accuracy.toStringAsFixed(0)}m accuracy',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to get location';

        if (e.toString().contains('permissions')) {
          errorMessage =
              'Location permission required. Please enable in settings.';
        } else if (e.toString().contains('disabled')) {
          errorMessage =
              'Location services disabled. Please enable in device settings.';
        }

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                if (e.toString().contains('permissions')) {
                  LocationService.instance.openAppSettings();
                } else {
                  LocationService.instance.openLocationSettings();
                }
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<String?> _reverseGeocode(double latitude, double longitude) async {
    return await GeocodingService.reverseGeocode(latitude, longitude);
  }

  Future<void> _updateLocationAddress() async {
    setState(() {
      _isGeocodingAddress = true;
    });

    final address = await _reverseGeocode(
      _selectedLatitude,
      _selectedLongitude,
    );

    if (mounted) {
      setState(() {
        _selectedLocationAddress = address != null
            ? GeocodingService.formatAddress(address)
            : null;
        _isGeocodingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            tooltip: 'Get current location',
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pop(context, {
                      'latitude': _selectedLatitude,
                      'longitude': _selectedLongitude,
                      'radius': _currentRadius,
                      'address': _selectedLocationAddress,
                    });
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Done'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_selectedLatitude, _selectedLongitude),
              initialZoom: 18.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLatitude = point.latitude;
                  _selectedLongitude = point.longitude;
                  _selectedLocationAddress = null; // Clear previous address
                });
                _updateLocationAddress(); // Get new address
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.agos',
              ),
              if (widget.showCoverageCircle)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(_selectedLatitude, _selectedLongitude),
                      radius: _currentRadius.toDouble(),
                      useRadiusInMeter:
                          true, // This ensures proper meter-based radius
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderStrokeWidth: 2,
                      borderColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_selectedLatitude, _selectedLongitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: _showLocationPicker,
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Location info overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildLocationInfo(theme),
          ),

          // Current location button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: "current_location",
              onPressed: _getCurrentLocation,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Zoom controls with better visibility
          Positioned(
            bottom: 170,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final zoom = _mapController.camera.zoom;
                            _mapController.move(
                              LatLng(_selectedLatitude, _selectedLongitude),
                              zoom + 1,
                            );
                          },
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(Icons.add, color: Colors.black87),
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final zoom = _mapController.camera.zoom;
                            _mapController.move(
                              LatLng(_selectedLatitude, _selectedLongitude),
                              zoom - 1,
                            );
                          },
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Radius control (only show if coverage circle is enabled)
          if (widget.showCoverageCircle)
            Positioned(
              bottom: 170,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.radio_button_unchecked,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Radius: ${_currentRadius}m',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (_currentRadius > 25) {
                                setState(() {
                                  _currentRadius = (_currentRadius - 25).clamp(
                                    25,
                                    1000,
                                  );
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showRadiusEditor,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$_currentRadius',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (_currentRadius < 1000) {
                                setState(() {
                                  _currentRadius = (_currentRadius + 25).clamp(
                                    25,
                                    1000,
                                  );
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Instructions overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 80,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Tap on the map to select location • Tap marker for coordinates',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected Location',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lat: ${_selectedLatitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(
                  'Lng: ${_selectedLongitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isGeocodingAddress)
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Getting address...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          else if (_selectedLocationAddress != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place, size: 14, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _selectedLocationAddress!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _selectedLocationAddress!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Copy address',
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to get address',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: _updateLocationAddress,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Refresh address',
                ),
              ],
            ),
          if (widget.showCoverageCircle) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Coverage: ${_currentRadius}m radius',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRadiusEditor() {
    final controller = TextEditingController(text: _currentRadius.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Coverage Radius'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Radius (meters)',
                border: OutlineInputBorder(),
                suffixText: 'm',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Range: 25m - 1000m',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newRadius = int.tryParse(controller.text);
              if (newRadius != null && newRadius >= 25 && newRadius <= 1000) {
                setState(() {
                  _currentRadius = newRadius;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid radius (25-1000m)'),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() {
    final latController = TextEditingController(
      text: _selectedLatitude.toStringAsFixed(6),
    );
    final lngController = TextEditingController(
      text: _selectedLongitude.toStringAsFixed(6),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Coordinates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);

              if (lat != null && lng != null) {
                setState(() {
                  _selectedLatitude = lat;
                  _selectedLongitude = lng;
                  _selectedLocationAddress = null;
                });
                _updateLocationAddress();
                _mapController.move(
                  LatLng(lat, lng),
                  _mapController.camera.zoom,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
