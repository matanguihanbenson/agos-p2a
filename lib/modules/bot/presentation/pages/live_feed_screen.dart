import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class LiveFeedScreen extends StatefulWidget {
  final DocumentSnapshot botDoc;

  const LiveFeedScreen({super.key, required this.botDoc});

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen>
    with TickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  bool _isConnected = false;
  bool _isRecording = false;
  bool _isFullscreen = false;
  Map<String, dynamic> _sensorData = {};
  String _streamQuality = 'HD';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _subscribeToSensorData();
    _simulateConnection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  void _subscribeToSensorData() {
    _sensorSubscription = _database
        .child('bots')
        .child(widget.botDoc.id)
        .child('sensors')
        .onValue
        .listen((event) {
          if (mounted && event.snapshot.exists) {
            final data = event.snapshot.value;
            if (data is Map) {
              setState(() {
                _sensorData = Map<String, dynamic>.from(data);
              });
            }
          }
        });
  }

  void _simulateConnection() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording ? 'Recording started' : 'Recording stopped'),
        backgroundColor: _isRecording ? Colors.red : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final botData = widget.botDoc.data() as Map<String, dynamic>;
    final botName = botData['name'] ?? 'Bot ${widget.botDoc.id}';

    if (_isFullscreen) {
      return _buildFullscreenView(colorScheme, botName);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildEnhancedAppBar(colorScheme, botName),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildEnhancedVideoFeed(colorScheme, botName),
            _buildSensorData(colorScheme),
            _buildBotInfo(colorScheme, botData),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar(
    ColorScheme colorScheme,
    String botName,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? Colors.red.withOpacity(
                              0.3 + (_pulseAnimation.value * 0.7),
                            )
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE STREAM',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Text(
            botName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        // Stream quality indicator
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: Text(
            _streamQuality,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Live status
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isConnected ? Colors.red : Colors.grey,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isConnected
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Text(
            _isConnected ? 'LIVE' : 'OFFLINE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedVideoFeed(ColorScheme colorScheme, String botName) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 12,
        shadowColor: _isConnected
            ? Colors.red.withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black, Colors.grey[900]!],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _buildVideoPlayer(colorScheme),
                    // Live streaming overlay
                    if (_isConnected)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: AnimatedBuilder(
                          animation: _waveAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(
                                      0.5 * _waveAnimation.value,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.videocam,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Camera Feed',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                botName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (_isConnected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'STREAMING',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildControlButton(
                              icon: _isRecording
                                  ? Icons.stop
                                  : Icons.fiber_manual_record,
                              label: _isRecording
                                  ? 'Stop Recording'
                                  : 'Start Recording',
                              color: _isRecording
                                  ? Colors.red
                                  : Colors.grey[700]!,
                              onPressed: _toggleRecording,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildControlButton(
                            icon: Icons.fullscreen,
                            label: 'Fullscreen',
                            color: Colors.blue,
                            onPressed: _toggleFullscreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenView(ColorScheme colorScheme, String botName) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _buildVideoPlayer(colorScheme, isFullscreen: true)),
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: _toggleFullscreen,
                    icon: const Icon(
                      Icons.fullscreen_exit,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isConnected ? 'LIVE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 16,
            child: SafeArea(
              child: FloatingActionButton(
                backgroundColor: _isRecording
                    ? Colors.red
                    : Colors.white.withOpacity(0.8),
                foregroundColor: _isRecording ? Colors.white : Colors.black,
                onPressed: _toggleRecording,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoFeed(ColorScheme colorScheme, String botName) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoPlayer(colorScheme),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.videocam, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Camera Feed - $botName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _buildControlButton(
                      icon: _isRecording
                          ? Icons.stop
                          : Icons.fiber_manual_record,
                      label: _isRecording ? 'Stop' : 'Record',
                      color: _isRecording ? Colors.red : colorScheme.primary,
                      onPressed: _toggleRecording,
                    ),
                    const SizedBox(width: 8),
                    _buildControlButton(
                      icon: Icons.fullscreen,
                      label: 'Fullscreen',
                      color: colorScheme.secondary,
                      onPressed: _toggleFullscreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(
    ColorScheme colorScheme, {
    bool isFullscreen = false,
  }) {
    return Container(
      width: double.infinity,
      height: isFullscreen ? double.infinity : 240,
      color: Colors.black,
      child: _isConnected
          ? Stack(
              children: [
                // Simulated video feed
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF3B82F6),
                        Color(0xFF06B6D4),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam,
                          color: Colors.white.withOpacity(0.8),
                          size: isFullscreen ? 80 : 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Live Video Stream',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isFullscreen ? 20 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isFullscreen) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap fullscreen for better view',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isRecording)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'REC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to bot camera...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSensorData(ColorScheme colorScheme) {
    final sensors = [
      {
        'label': 'Water Quality',
        'value': _sensorData['water_quality']?.toString() ?? '7.2 pH',
        'icon': Icons.water_drop,
        'color': Colors.blue,
      },
      {
        'label': 'Temperature',
        'value': _sensorData['temperature']?.toString() ?? '28°C',
        'icon': Icons.thermostat,
        'color': Colors.orange,
      },
      {
        'label': 'Turbidity',
        'value': _sensorData['turbidity']?.toString() ?? '12 NTU',
        'icon': Icons.visibility,
        'color': Colors.green,
      },
      {
        'label': 'Battery',
        'value': _sensorData['battery']?.toString() ?? '78%',
        'icon': Icons.battery_std,
        'color': Colors.purple,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sensors, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Real-time Sensor Data',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: sensors.length,
                itemBuilder: (context, index) {
                  final sensor = sensors[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (sensor['color'] as Color).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (sensor['color'] as Color).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sensor['icon'] as IconData,
                          color: sensor['color'] as Color,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sensor['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sensor['value'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sensor['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotInfo(ColorScheme colorScheme, Map<String, dynamic> botData) {
    final infoItems = [
      {
        'icon': Icons.circle,
        'label': 'Status',
        'value': botData['status']?.toString() ?? 'Unknown',
        'color': Colors.green,
      },
      {
        'icon': Icons.location_on,
        'label': 'Location',
        'value': 'Lat: 13.41, Lng: 121.17',
        'color': Colors.blue,
      },
      {
        'icon': Icons.timer,
        'label': 'Mission Time',
        'value': '1h 23m',
        'color': Colors.orange,
      },
      {
        'icon': Icons.update,
        'label': 'Last Update',
        'value': 'Just now',
        'color': Colors.purple,
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Bot Information',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: infoItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (item['color'] as Color).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: item['color'] as Color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['value'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature feature coming soon')));
  }
}
