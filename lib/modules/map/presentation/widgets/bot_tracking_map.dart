import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class BotTrackingMap extends StatefulWidget {
  const BotTrackingMap({super.key});

  @override
  State<BotTrackingMap> createState() => _BotTrackingMapState();
}

class _BotTrackingMapState extends State<BotTrackingMap> {
  final DatabaseReference _botsRef = FirebaseDatabase.instance.ref('bots');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  Map<String, LatLng> _botLocations = {};
  Map<String, Map<String, dynamic>> _botDetails = {};
  Map<String, String> _botAddresses = {};
  Map<String, String> _botNames = {};
  String? _selectedBotId;
  LatLng? _selectedBotPosition;
  StreamSubscription<DatabaseEvent>? _sub;
  bool _showBotList = false;
  bool _isBotListExpanded = false; // Add this line
  String? _currentUserRole;
  String? _currentUserId;
  Set<String> _allowedBotIds = {};

  bool _isMapLoading = true;
  String? _mapError;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _checkMapTiles();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _getUserRole();
      await _getAllowedBotIds();
      _listenToRealtimebots();
    }
  }

  Future<void> _getUserRole() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (userDoc.exists) {
        _currentUserRole = userDoc.data()?['role'];
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
  }

  Future<void> _getAllowedBotIds() async {
    try {
      if (_currentUserRole == 'admin') {
        final querySnapshot = await _firestore
            .collection('bots')
            .where('owner_admin_id', isEqualTo: _currentUserId)
            .get();

        _allowedBotIds = querySnapshot.docs.map((doc) => doc.id).toSet();

        for (var doc in querySnapshot.docs) {
          _botNames[doc.id] = doc.data()['name'] ?? 'Bot ${doc.id}';
        }
      } else if (_currentUserRole == 'field_operator') {
        final querySnapshot = await _firestore
            .collection('bots')
            .where('assigned_to', isEqualTo: _currentUserId)
            .get();

        _allowedBotIds = querySnapshot.docs.map((doc) => doc.id).toSet();

        for (var doc in querySnapshot.docs) {
          _botNames[doc.id] = doc.data()['name'] ?? 'Bot ${doc.id}';
        }
      } else {
        // For other roles or if role is not recognized, show no bots
        _allowedBotIds = <String>{};
        _botNames = <String, String>{};
      }

      print('Current user role: $_currentUserRole');
      print('Current user ID: $_currentUserId');
      print('Allowed bot IDs: $_allowedBotIds');
      print('Bot names: $_botNames');

      // If no bots are found for field operator, show a message
      if (_currentUserRole == 'field_operator' && _allowedBotIds.isEmpty) {
        print('No bots assigned to this field operator');
      }
    } catch (e) {
      print('Error getting allowed bot IDs: $e');
      // Reset to empty sets on error
      _allowedBotIds = <String>{};
      _botNames = <String, String>{};
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? 'Address not found';
      } else {
        return 'Unable to get address';
      }
    } catch (e) {
      print('Error getting address: $e');
      return 'Address unavailable';
    }
  }

  void _listenToRealtimebots() {
    _sub = _botsRef.onValue.listen(
      (event) {
        final botsData = event.snapshot.value as Map<dynamic, dynamic>?;

        if (botsData == null) {
          if (mounted) {
            setState(() {
              _botLocations.clear();
              _botDetails.clear();
              _botAddresses.clear();
              _selectedBotId = null;
              _selectedBotPosition = null;
            });
          }
          return;
        }

        final updatedLocations = <String, LatLng>{};
        final updatedDetails = <String, Map<String, dynamic>>{};

        botsData.forEach((key, value) {
          final botId = key.toString();

          // Only process bots that are in the allowed list for this user
          if (!_allowedBotIds.contains(botId)) {
            print(
              'Bot $botId not in allowed list for user $_currentUserId (role: $_currentUserRole)',
            );
            return;
          }

          if (value is Map) {
            final lat = value['lat'];
            final lng = value['lng'];

            if (lat != null && lng != null) {
              final latDouble = (lat as num).toDouble();
              final lngDouble = (lng as num).toDouble();
              updatedLocations[botId] = LatLng(latDouble, lngDouble);
              updatedDetails[botId] = {
                'name': value['name'] ?? _botNames[botId] ?? 'Bot $botId',
                'status': value['status'] ?? 'unknown',
                'active': value['active'] ?? false,
                'battery': value['battery'] ?? 0,
                'lastUpdate': DateTime.now().millisecondsSinceEpoch,
              };

              if (!_botAddresses.containsKey(botId)) {
                _getAddressFromCoordinates(latDouble, lngDouble).then((
                  address,
                ) {
                  if (mounted) {
                    setState(() {
                      _botAddresses[botId] = address;
                    });
                  }
                });
              }
            }
          }
        });

        if (mounted) {
          setState(() {
            _botLocations = updatedLocations;
            _botDetails = updatedDetails;
            if (_botLocations.isNotEmpty && _selectedBotId == null) {
              final first = _botLocations.entries.first;
              _selectedBotId = first.key;
              _selectedBotPosition = first.value;
              _mapController.move(first.value, 14);
            } else if (_selectedBotId != null &&
                !_botLocations.containsKey(_selectedBotId)) {
              _selectedBotId = null;
              _selectedBotPosition = null;
            } else if (_selectedBotId != null &&
                _botLocations.containsKey(_selectedBotId!)) {
              _selectedBotPosition = _botLocations[_selectedBotId!];
            }
          });
        }
      },
      onError: (error) {
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

    if (!_botAddresses.containsKey(botId)) {
      _getAddressFromCoordinates(position.latitude, position.longitude).then((
        address,
      ) {
        if (mounted) {
          setState(() {
            _botAddresses[botId] = address;
          });
        }
      });
    }

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
    final address = _botAddresses[botId] ?? 'Loading address...';

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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
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
          _buildDetailCard([
            _buildInfoRow(
              Icons.location_on_rounded,
              'Coordinates',
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
              isMultiline: true,
            ),
            _buildInfoRow(
              Icons.place_rounded,
              'Address',
              address,
              isMultiline: true,
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
          ], colorScheme),
          const SizedBox(height: 24),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isMultiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    maxLines: null,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
              ],
            )
          : Row(
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
                Flexible(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
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

  Widget _buildBotLabel(String botId, LatLng position) {
    final details = _botDetails[botId];
    final botName = _botNames[botId] ?? 'Bot $botId';
    final isActive = details?['active'] == true;
    final battery = details?['battery'] ?? 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            botName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE57373),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${battery}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
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

  Widget _buildBotListPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isBotListExpanded ? 300 : 0,
      width: 250,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isBotListExpanded
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_boat_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bots (${_botLocations.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _botLocations.length,
                    itemBuilder: (context, index) {
                      final entry = _botLocations.entries.elementAt(index);
                      final botId = entry.key;
                      final position = entry.value;
                      final details = _botDetails[botId];
                      final botName = _botNames[botId] ?? 'Bot $botId';
                      final isActive = details?['active'] == true;
                      final battery = details?['battery'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: _selectedBotId == botId
                              ? colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _selectedBotId == botId
                              ? Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                )
                              : null,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isActive
                                    ? [
                                        const Color(0xFF4CAF50),
                                        const Color(0xFF2E7D32),
                                      ]
                                    : [
                                        const Color(0xFFE57373),
                                        const Color(0xFFD32F2F),
                                      ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_boat_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            botName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE57373),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${battery}% • ${isActive ? 'Active' : 'Offline'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedBotId = botId;
                              _selectedBotPosition = position;
                              _isBotListExpanded = false;
                            });
                            _mapController.move(position, 16);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _checkMapTiles() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://tile.openstreetmap.org/1/0/0.png'),
            headers: {'User-Agent': 'AgosBotTracker/1.0'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _isMapLoading = false;
          _mapError = null;
        });
      } else {
        setState(() {
          _isMapLoading = false;
          _mapError = 'Map tiles server returned ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isMapLoading = false;
        _mapError = 'Failed to load map tiles: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Show loading or error state
    if (_isMapLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading map...', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (_mapError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Map Error',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _mapError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isMapLoading = true;
                    _mapError = null;
                  });
                  _checkMapTiles();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show message if no bots are available for field operator
    if (_currentUserRole == 'field_operator' &&
        _botLocations.isEmpty &&
        !_isMapLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_boat_outlined,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No Bots Assigned',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'You have no bots assigned to you. Please contact your administrator.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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

    // Create label markers positioned below bot markers with dynamic offset based on zoom
    final labelMarkers = _botLocations.entries.map((entry) {
      final botId = entry.key;
      final position = entry.value;
      final currentZoom = _mapController.camera.zoom;

      // Calculate dynamic offset based on zoom level - more offset at higher zoom levels
      final latOffset = 0.0001 * (21 - currentZoom).clamp(1, 15);

      return Marker(
        point: LatLng(position.latitude - latOffset, position.longitude),
        width: 120,
        height: 50,
        child: Center(
          child: GestureDetector(
            onTap: () => _onBotTap(botId, position),
            child: _buildBotLabel(botId, position),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedBotPosition ?? LatLng(13.4024, 122.5632),
              initialZoom: 13,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedBotId = null;
                  _selectedBotPosition = null;
                  _isBotListExpanded = false;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.agos.bottracker',
                maxZoom: 19,
                maxNativeZoom: 19,
                tileSize: 256,
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                },
                errorTileCallback: (tile, error, stackTrace) {
                  print('Tile loading error: $error');
                },
              ),
              MarkerLayer(markers: markers),
              MarkerLayer(markers: labelMarkers),
            ],
          ),

          // Zoom controls (left side)
          Positioned(top: 30, left: 16, child: _buildControlPanel()),

          // Floating recenter button
          Positioned(
            right: 16,
            bottom: 24,
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

          // Bot list panel (top right)
          if (_botLocations.isNotEmpty)
            Positioned(
              top: 30,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBotListPanel(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBotListExpanded = !_isBotListExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
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
                          const SizedBox(width: 4),
                          Icon(
                            _isBotListExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
