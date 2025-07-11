import 'package:flutter/material.dart';
import 'dart:async';

enum BluetoothConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  failed,
}

class BluetoothConnectionWidget extends StatefulWidget {
  final String botId;
  final Function(bool isConnected) onConnectionChanged;
  final VoidCallback? onRetry;

  const BluetoothConnectionWidget({
    Key? key,
    required this.botId,
    required this.onConnectionChanged,
    this.onRetry,
  }) : super(key: key);

  @override
  State<BluetoothConnectionWidget> createState() =>
      _BluetoothConnectionWidgetState();
}

class _BluetoothConnectionWidgetState extends State<BluetoothConnectionWidget>
    with TickerProviderStateMixin {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  late AnimationController _scanningController;
  late AnimationController _pulseController;
  late Animation<double> _scanningAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _connectionTimer;
  String _statusMessage = '';
  double _connectionProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startConnectionProcess();
  }

  void _setupAnimations() {
    _scanningController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scanningAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanningController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _scanningController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startConnectionProcess() {
    setState(() {
      _connectionState = BluetoothConnectionState.scanning;
      _statusMessage = 'Scanning for bot devices...';
      _connectionProgress = 0.0;
    });

    _scanningController.repeat();

    // Simulate scanning phase
    _connectionTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _simulateDeviceFound();
      }
    });
  }

  void _simulateDeviceFound() {
    setState(() {
      _connectionState = BluetoothConnectionState.connecting;
      _statusMessage = 'Bot found! Connecting to ${_getBotBluetoothName()}...';
      _connectionProgress = 0.3;
    });

    _scanningController.stop();
    _pulseController.repeat(reverse: true);

    // Simulate connection progress
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _connectionProgress += 0.2;
      });

      if (_connectionProgress >= 1.0) {
        timer.cancel();
        _simulateConnectionResult();
      }
    });
  }

  void _simulateConnectionResult() {
    // Simulate 85% success rate
    final isSuccess = DateTime.now().millisecond % 100 < 85;

    if (isSuccess) {
      setState(() {
        _connectionState = BluetoothConnectionState.connected;
        _statusMessage = 'Connected to ${_getBotBluetoothName()}';
        _connectionProgress = 1.0;
      });
      _pulseController.stop();
      widget.onConnectionChanged(true);
    } else {
      setState(() {
        _connectionState = BluetoothConnectionState.failed;
        _statusMessage =
            'Failed to connect to bot. Check if bot is nearby and powered on.';
        _connectionProgress = 0.0;
      });
      _pulseController.stop();
      widget.onConnectionChanged(false);
    }
  }

  String _getBotBluetoothName() {
    // Format: AGOS-BOT-ID becomes AGOS_BT_ID for Bluetooth
    return 'AGOS_BT_${widget.botId.replaceAll('AGOS-BOT-', '')}';
  }

  void _retry() {
    _connectionTimer?.cancel();
    _scanningController.reset();
    _pulseController.reset();
    _startConnectionProcess();
    if (widget.onRetry != null) {
      widget.onRetry!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConnectionIcon(),
          const SizedBox(height: 16),
          _buildStatusText(),
          const SizedBox(height: 16),
          _buildProgressIndicator(),
          const SizedBox(height: 20),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildConnectionIcon() {
    Widget icon;
    Color iconColor;

    switch (_connectionState) {
      case BluetoothConnectionState.disconnected:
        icon = const Icon(Icons.bluetooth_disabled, size: 48);
        iconColor = const Color(0xFF9CA3AF);
        break;
      case BluetoothConnectionState.scanning:
        icon = AnimatedBuilder(
          animation: _scanningAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _scanningAnimation.value * 2 * 3.14159,
              child: const Icon(Icons.bluetooth_searching, size: 48),
            );
          },
        );
        iconColor = const Color(0xFF3B82F6);
        break;
      case BluetoothConnectionState.connecting:
        icon = AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: const Icon(Icons.bluetooth_connected, size: 48),
            );
          },
        );
        iconColor = const Color(0xFF3B82F6);
        break;
      case BluetoothConnectionState.connected:
        icon = const Icon(Icons.bluetooth_connected, size: 48);
        iconColor = const Color(0xFF059669);
        break;
      case BluetoothConnectionState.failed:
        icon = const Icon(Icons.bluetooth_disabled, size: 48);
        iconColor = const Color(0xFFDC2626);
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(iconTheme: IconThemeData(color: iconColor)),
          child: icon,
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    return Column(
      children: [
        Text(
          _getStatusTitle(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _getStatusColor(),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _statusMessage,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          textAlign: TextAlign.center,
        ),
        if (_connectionState == BluetoothConnectionState.connecting) ...[
          const SizedBox(height: 8),
          Text(
            'Target: ${_getBotBluetoothName()}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator() {
    if (_connectionState == BluetoothConnectionState.scanning) {
      return SizedBox(
        width: double.infinity,
        child: LinearProgressIndicator(
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          minHeight: 6,
        ),
      );
    }

    if (_connectionState == BluetoothConnectionState.connecting) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: _connectionProgress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3B82F6),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_connectionProgress * 100).round()}%',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton() {
    switch (_connectionState) {
      case BluetoothConnectionState.failed:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      case BluetoothConnectionState.connected:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
              SizedBox(width: 8),
              Text(
                'Bluetooth Connected',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getConnectionHint(),
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        );
    }
  }

  String _getStatusTitle() {
    switch (_connectionState) {
      case BluetoothConnectionState.disconnected:
        return 'Bluetooth Disconnected';
      case BluetoothConnectionState.scanning:
        return 'Scanning for Bot';
      case BluetoothConnectionState.connecting:
        return 'Connecting to Bot';
      case BluetoothConnectionState.connected:
        return 'Bluetooth Connected';
      case BluetoothConnectionState.failed:
        return 'Connection Failed';
    }
  }

  Color _getStatusColor() {
    switch (_connectionState) {
      case BluetoothConnectionState.disconnected:
        return const Color(0xFF9CA3AF);
      case BluetoothConnectionState.scanning:
      case BluetoothConnectionState.connecting:
        return const Color(0xFF3B82F6);
      case BluetoothConnectionState.connected:
        return const Color(0xFF059669);
      case BluetoothConnectionState.failed:
        return const Color(0xFFDC2626);
    }
  }

  String _getConnectionHint() {
    switch (_connectionState) {
      case BluetoothConnectionState.disconnected:
        return 'Ensure bot is powered on and Bluetooth is enabled';
      case BluetoothConnectionState.scanning:
        return 'Searching for nearby bot devices...';
      case BluetoothConnectionState.connecting:
        return 'Establishing secure connection...';
      default:
        return '';
    }
  }
}
