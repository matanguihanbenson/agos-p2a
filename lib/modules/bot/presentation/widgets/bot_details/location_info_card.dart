import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationInfoCard extends StatefulWidget {
  final double? lat;
  final double? lng;
  final String? accuracy;
  final ColorScheme cs;
  final Function(List<double>?)? onBoundingBoxChanged;

  const LocationInfoCard({
    Key? key,
    this.lat,
    this.lng,
    this.accuracy,
    required this.cs,
    this.onBoundingBoxChanged,
  }) : super(key: key);

  @override
  State<LocationInfoCard> createState() => _LocationInfoCardState();
}

class _LocationInfoCardState extends State<LocationInfoCard> {
  String? _address;
  bool _isLoading = false;
  bool _geocodingFailed = false;
  String? _errorMessage;
  List<double>? _boundingBox;

  @override
  void initState() {
    super.initState();
    _geocodeLocation();
  }

  void _setBoundingBox(List<double>? boundingBox) {
    _boundingBox = boundingBox;
    if (widget.onBoundingBoxChanged != null) {
      widget.onBoundingBoxChanged!(boundingBox);
    }
  }

  Future<String?> _getAddressFromLatLng(double lat, double lng) async {
    if (kIsWeb) {
      // For web, use BigDataCloud API which supports CORS
      return _getAddressFromLatLngAlternative(lat, lng);
    } else {
      // For mobile, use Nominatim API
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng';

      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {'User-Agent': 'AGOS FlutterApp/1.0 (contact@agos.app)'},
            )
            .timeout(const Duration(seconds: 10));

        if (kDebugMode) {
          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');
        }

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final displayName = data['display_name'] as String?;

          // Store bounding box if available from Nominatim
          if (data['boundingbox'] != null) {
            final bbox = data['boundingbox'] as List;
            if (bbox.length == 4) {
              final boundingBox = bbox
                  .map((e) => double.tryParse(e.toString()) ?? 0.0)
                  .toList();

              _setBoundingBox(boundingBox);

              if (kDebugMode) {
                print('Nominatim bounding box: $boundingBox');
              }
            }
          }

          if (kDebugMode) {
            print('Display name: $displayName');
          }

          return displayName;
        } else {
          if (kDebugMode) {
            print('HTTP Error: ${response.statusCode}');
          }
          return null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Nominatim API error: $e');
        }
        return null;
      }
    }
  }

  // Alternative geocoding approach for web using BigDataCloud
  Future<String?> _getAddressFromLatLngAlternative(
    double lat,
    double lng,
  ) async {
    try {
      // Use BigDataCloud API which supports CORS and is free
      final url =
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en';

      if (kDebugMode) {
        print('Using BigDataCloud API: $url');
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('BigDataCloud Response status: ${response.statusCode}');
        print('BigDataCloud Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store bounding box if available
        if (data['boundingbox'] != null) {
          final bbox = data['boundingbox'] as List;
          if (bbox.length == 4) {
            final boundingBox = bbox
                .map((e) => double.tryParse(e.toString()) ?? 0.0)
                .toList();

            _setBoundingBox(boundingBox);
          }
        }

        // Format address from BigDataCloud response using only proper address components
        final addressParts = <String>[];

        // Get specific address components in order of specificity
        final locality = data['locality']?.toString() ?? '';
        final city = data['city']?.toString() ?? '';
        final principalSubdivision =
            data['principalSubdivision']?.toString() ?? '';
        final countryName = _cleanCountryName(
          data['countryName']?.toString() ?? '',
        );

        // Get sublocality from administrative array safely
        String sublocality = '';
        final localityInfo = data['localityInfo'];
        if (localityInfo != null && localityInfo['administrative'] != null) {
          final administrative = localityInfo['administrative'] as List;
          // Safely check if index 3 exists and get the province/state name
          if (administrative.length > 2) {
            sublocality = administrative[2]['name']?.toString() ?? '';
          }
        }

        if (locality.isNotEmpty && !_isGenericDescription(locality)) {
          addressParts.add(locality);
        }

        if (sublocality.isNotEmpty &&
            sublocality != locality &&
            sublocality != city &&
            !_isGenericDescription(sublocality)) {
          addressParts.add(sublocality);
        }

        if (city.isNotEmpty &&
            city != locality &&
            city != sublocality &&
            !_isGenericDescription(city)) {
          addressParts.add(city);
        }

        if (principalSubdivision.isNotEmpty &&
            principalSubdivision != city &&
            principalSubdivision != sublocality &&
            !_isGenericDescription(principalSubdivision)) {
          addressParts.add(principalSubdivision);
        }

        if (countryName.isNotEmpty && !_isGenericDescription(countryName)) {
          addressParts.add(countryName);
        }

        final formattedAddress = addressParts.isNotEmpty
            ? addressParts.join(', ')
            : null;

        if (kDebugMode) {
          print('Formatted address: $formattedAddress');
          print('Bounding box: $_boundingBox');
        }

        return formattedAddress;
      }
    } catch (e) {
      if (kDebugMode) {
        print('BigDataCloud geocoding error: $e');
      }
    }
    return null;
  }

  // Helper method to clean up country names
  String _cleanCountryName(String countryName) {
    if (countryName.isEmpty) return countryName;

    // Remove common parenthetical additions like "(the)"
    return countryName
        .replaceAll(RegExp(r'\s*\(the\)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\(Republic of\)\s*', caseSensitive: false), '')
        .trim();
  }

  // Helper method to filter out generic descriptions
  bool _isGenericDescription(String description) {
    final genericTerms = [
      'biggest continent in the world',
      'largest continent',
      'continent',
      'world',
      'earth',
      'planet',
      'globe',
      'asia',
      'africa',
      'europe',
      'north america',
      'south america',
      'australia',
      'antarctica',
    ];

    final lowerDesc = description.toLowerCase();
    return genericTerms.any((term) => lowerDesc.contains(term));
  }

  Future<void> _geocodeLocation() async {
    if (widget.lat == null || widget.lng == null) {
      if (kDebugMode) {
        print('Invalid coordinates: lat=${widget.lat}, lng=${widget.lng}');
      }
      setState(() {
        _geocodingFailed = true;
        _errorMessage = 'Invalid coordinates';
      });
      return;
    }

    if (kDebugMode) {
      print('Starting geocoding for: ${widget.lat}, ${widget.lng}');
    }

    setState(() {
      _isLoading = true;
      _geocodingFailed = false;
      _errorMessage = null;
    });

    try {
      final address = await _getAddressFromLatLng(widget.lat!, widget.lng!);

      if (kDebugMode) {
        print('Received address: $address');
      }

      if (mounted) {
        if (address != null && address.isNotEmpty) {
          setState(() {
            _address = address;
            _geocodingFailed = false;
          });

          if (kDebugMode) {
            print('Address set successfully: $_address');
          }
        } else {
          setState(() {
            _geocodingFailed = true;
            _errorMessage = 'No address found for coordinates';
          });

          if (kDebugMode) {
            print('No address found or empty address');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Address lookup error: $e');
      }
      if (mounted) {
        setState(() {
          _geocodingFailed = true;
          _errorMessage = 'Failed to get address';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(
        'Building LocationInfoCard - address: $_address, loading: $_isLoading, failed: $_geocodingFailed',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.cs.outline.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: widget.cs.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.cs.onSurface,
                      ),
                    ),
                    if (widget.accuracy != null)
                      Text(
                        'Accuracy: ±${widget.accuracy}m',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Getting location...',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            )
          else ...[
            // Show address if available
            if (_address != null && !_geocodingFailed) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _address!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Always show coordinates
            Text(
              'Coordinates',
              style: TextStyle(
                fontSize: 12,
                color: widget.cs.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              '${widget.lat?.toStringAsFixed(6) ?? 'N/A'}, ${widget.lng?.toStringAsFixed(6) ?? 'N/A'}',
              style: TextStyle(
                fontSize: 12,
                color: widget.cs.onSurface.withOpacity(0.8),
              ),
            ),

            // Show error message or retry button if geocoding failed
            if (_geocodingFailed) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Address lookup failed',
                style: TextStyle(
                  fontSize: 11,
                  color: widget.cs.onSurface.withOpacity(0.5),
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _geocodeLocation,
                  child: Text(
                    'Tap to retry',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.cs.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
