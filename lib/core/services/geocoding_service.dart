import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeocodingService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  // Multiple CORS proxy options for better reliability
  static const List<String> _corsProxies = [
    'https://corsproxy.io/?',
    'https://api.codetabs.com/v1/proxy?quest=',
    'https://cors-anywhere.herokuapp.com/',
    'https://thingproxy.freeboard.io/fetch/',
  ];

  static Future<String?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      String url;
      Map<String, String> headers = {};

      if (kIsWeb) {
        // Try multiple CORS proxies for web
        for (int i = 0; i < _corsProxies.length; i++) {
          try {
            final proxy = _corsProxies[i];
            final targetUrl =
                '$_nominatimUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1&limit=1';

            if (proxy == 'https://api.codetabs.com/v1/proxy?quest=') {
              url = '$proxy${Uri.encodeComponent(targetUrl)}';
            } else if (proxy == 'https://corsproxy.io/?') {
              url = '$proxy${Uri.encodeComponent(targetUrl)}';
            } else {
              url = '$proxy$targetUrl';
            }

            if (kDebugMode) {
              print('Trying CORS proxy ${i + 1}: $proxy');
            }

            final response = await http
                .get(Uri.parse(url), headers: headers)
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              dynamic data;

              // Handle different proxy response formats
              if (proxy == 'https://api.codetabs.com/v1/proxy?quest=') {
                // CodeTabs returns the response directly
                data = json.decode(response.body);
              } else if (proxy == 'https://corsproxy.io/?') {
                // Corsproxy.io returns the response directly
                data = json.decode(response.body);
              } else {
                // Other proxies might wrap the response
                try {
                  final parsed = json.decode(response.body);
                  if (parsed is Map && parsed.containsKey('contents')) {
                    data = json.decode(parsed['contents']);
                  } else {
                    data = parsed;
                  }
                } catch (e) {
                  data = json.decode(response.body);
                }
              }

              if (data is Map && data['display_name'] != null) {
                if (kDebugMode) {
                  print('Successfully got address using proxy ${i + 1}');
                }
                return data['display_name'] as String;
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('CORS proxy ${i + 1} failed: $e');
            }
            // Continue to next proxy
          }
        }

        // If all CORS proxies fail, try alternative geocoding services
        try {
          // Try reverse geocoding with a simpler service (this is a fallback)
          final fallbackUrl =
              'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=en';

          final response = await http
              .get(Uri.parse(fallbackUrl))
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['display_name'] != null) {
              if (kDebugMode) {
                print('Successfully got address using BigDataCloud fallback');
              }
              return data['display_name'] as String;
            } else if (data['locality'] != null || data['city'] != null) {
              // Construct address from available parts
              final parts = <String>[];
              if (data['locality'] != null) parts.add(data['locality']);
              if (data['city'] != null && data['city'] != data['locality'])
                parts.add(data['city']);
              if (data['principalSubdivision'] != null)
                parts.add(data['principalSubdivision']);
              if (data['countryName'] != null) parts.add(data['countryName']);

              if (parts.isNotEmpty) {
                if (kDebugMode) {
                  print(
                    'Successfully got address parts using BigDataCloud fallback',
                  );
                }
                return parts.join(', ');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('BigDataCloud fallback failed: $e');
          }
        }

        // Final fallback: return approximate location
        if (kDebugMode) {
          print(
            'All geocoding services failed, returning coordinate-based location',
          );
        }
        return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      } else {
        // Direct call for mobile/desktop with proper headers
        url =
            '$_nominatimUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1&limit=1';
        headers['User-Agent'] = 'agos-p2a-app/1.0 (contact@example.com)';
        headers['Accept'] = 'application/json';
        headers['Accept-Language'] = 'en';

        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['display_name'] != null) {
            return data['display_name'] as String;
          }
        } else if (response.statusCode == 429) {
          // Rate limited, wait and retry once
          await Future.delayed(const Duration(seconds: 2));

          final retryResponse = await http
              .get(Uri.parse(url), headers: headers)
              .timeout(const Duration(seconds: 15));

          if (retryResponse.statusCode == 200) {
            final data = json.decode(retryResponse.body);
            if (data['display_name'] != null) {
              return data['display_name'] as String;
            }
          }
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
