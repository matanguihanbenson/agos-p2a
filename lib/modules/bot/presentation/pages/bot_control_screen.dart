import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math' as math;
import '../widgets/bluetooth_connection_widget.dart';

class BotControlScreen extends StatefulWidget {
  final DocumentSnapshot botDoc;

  const BotControlScreen({Key? key, required this.botDoc}) : super(key: key);

  @override
  State<BotControlScreen> createState() => _BotControlScreenState();
}

class _BotControlScreenState extends State<BotControlScreen>
    with TickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _subscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Map<String, dynamic>? _realtimeData;
  bool _isLoading = false;
  String? _lastCommand;
  DateTime? _lastCommandTime;
  bool _isConnected = false; // Database/Internet connection
  bool _isBluetoothConnected = false; // Bluetooth connection (independent)
  bool _isManualMode = false;

  // Joystick state
  Offset _joystickPosition = Offset.zero;
  bool _isDragging = false;
  Timer? _commandTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _subscribeToRealtimeData();
    _checkConnection();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    _commandTimer?.cancel();
    super.dispose();
  }

  void _subscribeToRealtimeData() {
    _subscription = _database
        .child('bots')
        .child(widget.botDoc.id)
        .onValue
        .listen(
          (event) {
            if (mounted && event.snapshot.exists) {
              final botData = event.snapshot.value;
              if (botData is Map) {
                setState(() {
                  _realtimeData = Map<String, dynamic>.from(botData);
                  _isConnected = _realtimeData?['active'] == true;
                });
              }
            }
          },
          onError: (error) {
            setState(() {
              _isConnected = false;
            });
          },
        );
  }

  void _checkConnection() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final lastSeen = _realtimeData?['last_seen'];
      if (lastSeen != null) {
        final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
        final isRecent = DateTime.now().difference(lastSeenTime).inMinutes < 2;

        if (_isConnected != isRecent) {
          setState(() {
            _isConnected = isRecent;
          });
        }
      }
    });
  }

  Future<void> _sendCommand(
    String command, {
    Map<String, dynamic>? params,
  }) async {
    // Check if Bluetooth is connected (primary requirement)
    if (!_isBluetoothConnected) {
      _showSnackBar(
        'Bluetooth not connected. Cannot send commands.',
        isError: true,
      );
      return;
    }

    if (!_isManualMode) {
      _showSnackBar('Switch to manual mode to send commands.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _lastCommand = command;
      _lastCommandTime = DateTime.now();
    });

    try {
      // Send command via Bluetooth (simulate for now)
      await _sendBluetoothCommand(command, params);

      // Try to log to database if connected, but don't fail if offline
      if (_isConnected) {
        try {
          final commandData = {
            'command': command,
            'timestamp': ServerValue.timestamp,
            'sent_by': FirebaseAuth.instance.currentUser?.uid,
            'params': params ?? {},
            'mode': 'manual',
            'sent_via': 'bluetooth',
          };

          await _database
              .child('bots')
              .child(widget.botDoc.id)
              .child('commands')
              .push()
              .set(commandData);
        } catch (e) {
          // Database logging failed, but Bluetooth command was sent
          print('Failed to log command to database: $e');
        }
      }

      _showSnackBar('Command sent via Bluetooth: ${command.toUpperCase()}');
    } catch (e) {
      _showSnackBar('Failed to send Bluetooth command: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Simulate Bluetooth command sending
  Future<void> _sendBluetoothCommand(
    String command,
    Map<String, dynamic>? params,
  ) async {
    // Simulate Bluetooth transmission delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Here you would integrate with actual Bluetooth API
    // For now, we'll just simulate success
    print('Bluetooth Command Sent: $command with params: $params');
  }

  void _handleJoystickMove(Offset position) {
    setState(() {
      _joystickPosition = position;
    });

    // Convert joystick position to movement commands
    final distance = position.distance;
    if (distance > 0.3) {
      // Minimum threshold for movement
      final angle = math.atan2(position.dy, position.dx);
      final degrees = (angle * 180 / math.pi + 360) % 360;

      String command;
      Map<String, dynamic> params = {
        'intensity': (distance * 100).clamp(0, 100).round(),
        'angle': degrees.round(),
      };

      if (degrees >= 315 || degrees < 45) {
        command = 'move_right';
      } else if (degrees >= 45 && degrees < 135) {
        command = 'move_backward';
      } else if (degrees >= 135 && degrees < 225) {
        command = 'move_left';
      } else {
        command = 'move_forward';
      }

      // Throttle commands to avoid spam
      _commandTimer?.cancel();
      _commandTimer = Timer(const Duration(milliseconds: 200), () {
        _sendCommand(command, params: params);
      });
    }
  }

  void _handleJoystickEnd() {
    setState(() {
      _joystickPosition = Offset.zero;
      _isDragging = false;
    });
    _commandTimer?.cancel();
    _sendCommand('stop');
  }

  void _toggleMode() {
    // Mode can be toggled if Bluetooth is connected, regardless of database status
    if (!_isBluetoothConnected) {
      _showSnackBar(
        'Connect via Bluetooth first to change modes.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isManualMode = !_isManualMode;
    });

    // Try to send mode change to database if connected
    if (_isConnected) {
      _sendModeCommand(_isManualMode ? 'manual' : 'automatic');
    }

    _showSnackBar(
      _isManualMode
          ? 'Switched to Manual Mode (Bluetooth)'
          : 'Switched to Automatic Mode (Bluetooth)',
    );
  }

  Future<void> _sendModeCommand(String mode) async {
    try {
      final modeData = {
        'mode': mode,
        'timestamp': ServerValue.timestamp,
        'sent_by': FirebaseAuth.instance.currentUser?.uid,
      };

      await _database
          .child('bots')
          .child(widget.botDoc.id)
          .child('mode')
          .set(modeData);
    } catch (e) {
      print('Failed to send mode command: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF1D4ED8),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.botDoc.data()! as Map<String, dynamic>;
    final botName = data['name']?.toString().trim();
    final displayName = (botName != null && botName.isNotEmpty)
        ? botName
        : 'Bot Control';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(displayName),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Status Bar
              _buildCompactStatus(),
              const SizedBox(height: 16),

              // Bluetooth Connection (only show when disconnected)
              if (!_isBluetoothConnected) ...[
                BluetoothConnectionWidget(
                  botId: widget.botDoc.id,
                  onConnectionChanged: (isConnected) {
                    setState(() {
                      _isBluetoothConnected = isConnected;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Mode Toggle
              _buildModeToggle(),
              const SizedBox(height: 20),

              // Main Control Section (Center Piece)
              _buildMainControlSection(),

              const SizedBox(height: 24),
              _buildOperationalControls(),
              const SizedBox(height: 24),
              _buildEmergencyControls(),

              if (_lastCommand != null) ...[
                const SizedBox(height: 20),
                _buildLastCommand(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String displayName) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF1E293B),
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.settings_remote_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatus() {
    final active = _realtimeData?['active'] ?? false;
    final battery = _realtimeData?['battery']?.toString() ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Database Connection Status
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isConnected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Database: ${_isConnected ? 'Online' : 'Offline'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isConnected
                      ? const Color(0xFF047857)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bluetooth Connection Status
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isBluetoothConnected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Bluetooth: ${_isBluetoothConnected ? 'Connected' : 'Disconnected'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isBluetoothConnected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFFDC2626),
                ),
              ),
              const Spacer(),
              if (_isBluetoothConnected) ...[
                Text(
                  'Power: ${active ? 'ON' : 'OFF'} • Battery: $battery',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),

          // Connection Priority Info
          if (!_isBluetoothConnected) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD97706)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFD97706), size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bluetooth required for control (works offline)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isManualMode ? Icons.touch_app : Icons.auto_mode,
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isManualMode ? 'Manual Control' : 'Automatic Mode',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _isManualMode
                          ? 'Direct Bluetooth control active'
                          : 'Bot operates automatically',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isManualMode,
                onChanged: _isBluetoothConnected ? (_) => _toggleMode() : null,
                activeColor: const Color(0xFF3B82F6),
                inactiveThumbColor: const Color(0xFF94A3B8),
                inactiveTrackColor: const Color(0xFFE2E8F0),
              ),
            ],
          ),
          if (!_isManualMode && _isBluetoothConnected) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bot is running automatically. Switch to manual for direct control.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainControlSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.05),
            const Color(0xFF1D4ED8).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_boat_rounded,
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Navigation Control',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Full Width Joystick
          SizedBox(
            width: double.infinity,
            height: 280,
            child: _JoystickWidget(
              onChanged: _handleJoystickMove,
              onEnded: _handleJoystickEnd,
              enabled: _isBluetoothConnected && _isManualMode && !_isLoading,
            ),
          ),

          const SizedBox(height: 16),
          Text(
            _getControlHint(),
            style: TextStyle(
              fontSize: 14,
              color: _getControlHintColor(),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getControlHint() {
    if (!_isBluetoothConnected) {
      return 'Connect via Bluetooth to enable navigation (works offline)';
    } else if (!_isManualMode) {
      return 'Switch to manual mode to control the bot';
    } else {
      return 'Drag to navigate the bot in any direction via Bluetooth';
    }
  }

  Color _getControlHintColor() {
    if (!_isBluetoothConnected || !_isManualMode) {
      return const Color(0xFF94A3B8);
    } else {
      return const Color(0xFF3B82F6);
    }
  }

  Widget _buildOperationalControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Operations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (!_isConnected && _isBluetoothConnected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BLUETOOTH ONLY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOperationalButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Start\nCollection',
                  onPressed: () => _sendCommand('start_collection'),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOperationalButton(
                  icon: Icons.pause_rounded,
                  label: 'Pause\nCollection',
                  onPressed: () => _sendCommand('pause_collection'),
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOperationalButton(
                  icon: Icons.home_rounded,
                  label: 'Return\nHome',
                  onPressed: () => _sendCommand('return_home'),
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOperationalButton(
                  icon: Icons.refresh_rounded,
                  label: 'Status\nUpdate',
                  onPressed: () => _sendCommand('status_update'),
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    final isEnabled =
        _isBluetoothConnected && !_isLoading; // Only require Bluetooth

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isEnabled ? color.withOpacity(0.1) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? color.withOpacity(0.3)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isEnabled ? color : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? color : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 18),
              SizedBox(width: 8),
              Text(
                'Emergency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed:
                  (_isBluetoothConnected &&
                      !_isLoading) // Only require Bluetooth
                  ? () => _showEmergencyDialog()
                  : null,
              icon: const Icon(Icons.emergency, size: 18),
              label: const Text(
                'EMERGENCY STOP',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastCommand() {
    if (_lastCommand == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Color(0xFF1D4ED8), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Last command: ${_lastCommand!.toUpperCase()} (${_formatTime(_lastCommandTime!)})',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 20),
            SizedBox(width: 8),
            Text('Emergency Stop'),
          ],
        ),
        content: const Text(
          'This will immediately stop all bot operations and movements. Are you sure you want to proceed?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendCommand('emergency_stop');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('EMERGENCY STOP'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _JoystickWidget extends StatefulWidget {
  final Function(Offset) onChanged;
  final VoidCallback onEnded;
  final bool enabled;

  const _JoystickWidget({
    required this.onChanged,
    required this.onEnded,
    required this.enabled,
  });

  @override
  State<_JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<_JoystickWidget> {
  Offset _position = Offset.zero;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.of(context).size.width - 80; // Full width minus padding
    final radius = size / 2;
    final knobRadius = radius * 0.3;
    final maxDistance = radius - knobRadius;

    return GestureDetector(
      onPanStart: widget.enabled ? _onPanStart : null,
      onPanUpdate: widget.enabled
          ? (details) => _onPanUpdate(details, radius, maxDistance)
          : null,
      onPanEnd: widget.enabled ? _onPanEnd : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: widget.enabled
              ? const Color(0xFFEBF8FF)
              : const Color(0xFFF8FAFC),
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.enabled
                ? const Color(0xFF3B82F6)
                : const Color(0xFFCBD5E1),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Center dot
            Positioned(
              left: radius - 4,
              top: radius - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Joystick knob
            AnimatedPositioned(
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: radius - knobRadius + (_position.dx * maxDistance),
              top: radius - knobRadius + (_position.dy * maxDistance),
              child: Container(
                width: knobRadius * 2,
                height: knobRadius * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.enabled
                        ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                        : [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A000000),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_boat_rounded,
                  color: Colors.white,
                  size: knobRadius * 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    double radius,
    double maxDistance,
  ) {
    final center = Offset(radius, radius);
    final localPosition = details.localPosition - center;
    final distance = localPosition.distance;

    if (distance <= maxDistance) {
      setState(() {
        _position = Offset(
          localPosition.dx / maxDistance,
          localPosition.dy / maxDistance,
        );
      });
    } else {
      final normalizedPosition = localPosition / distance;
      setState(() {
        _position = normalizedPosition;
      });
    }

    widget.onChanged(_position);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _position = Offset.zero;
      _isDragging = false;
    });
    widget.onEnded();
  }
}
