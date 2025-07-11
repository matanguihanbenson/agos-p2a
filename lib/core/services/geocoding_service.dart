import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeocodingService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const String _corsProxyUrl = 'https://api.allorigins.win/raw?url=';

  static Future<String?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      String url;
      Map<String, String> headers = {};

      if (kIsWeb) {
        // Use CORS proxy for web
        final encodedUrl = Uri.encodeComponent(
          '$_nominatimUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1&limit=1',
        );
        url = '$_corsProxyUrl$encodedUrl';
      } else {
        // Direct call for mobile/desktop
        url =
            '$_nominatimUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1&limit=1';
        headers['User-Agent'] = 'agos-p2a-app/1.0';
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'] as String;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Reverse geocoding error: $e');
      }
    }
    return null;
  }

  static String formatAddress(String fullAddress) {
    // Extract meaningful parts of the address
    final parts = fullAddress.split(', ');
    if (parts.length > 3) {
      // Take first 3-4 meaningful parts
      return parts.take(4).join(', ');
    }
    return fullAddress;
  }
}
