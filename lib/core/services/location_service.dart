import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  // High accuracy location settings
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
    timeLimit: Duration(seconds: 30), // Timeout after 30 seconds
  );

  // Best accuracy for web
  static const LocationSettings _webLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 5, // More sensitive for web
    timeLimit: Duration(seconds: 45), // Longer timeout for web
  );

  /// Get current location with high accuracy
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable location services in your device settings.',
        );
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            'Location permissions are denied. Please grant location access in app settings.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied. Please enable location access in app settings.',
        );
      }

      // Get location with appropriate settings
      final settings = kIsWeb ? _webLocationSettings : _locationSettings;

      Position position;
      if (forceRefresh || kIsWeb) {
        // Always get fresh location on web or when forced
        position = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        );
      } else {
        // Try to get last known position first (faster)
        Position? lastPosition = await Geolocator.getLastKnownPosition();

        if (lastPosition != null && _isLocationRecent(lastPosition)) {
          position = lastPosition;
        } else {
          position = await Geolocator.getCurrentPosition(
            locationSettings: settings,
          );
        }
      }

      if (kDebugMode) {
        print('Location obtained: ${position.latitude}, ${position.longitude}');
        print('Accuracy: ${position.accuracy}m');
        print('Timestamp: ${position.timestamp}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
      rethrow;
    }
  }

  /// Check if a position is recent (within 5 minutes)
  bool _isLocationRecent(Position position) {
    if (position.timestamp == null) return false;

    final now = DateTime.now();
    final diff = now.difference(position.timestamp!);
    return diff.inMinutes < 5;
  }

  /// Get location stream for continuous updates
  Stream<Position> getLocationStream() {
    final settings = kIsWeb ? _webLocationSettings : _locationSettings;

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check location permission status
  Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
