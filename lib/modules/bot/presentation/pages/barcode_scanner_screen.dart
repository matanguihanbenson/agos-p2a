import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _hasPermission = false;
  String? _errorMessage;
  bool _isScanning = true;
  bool _isTorchOn = false;
  bool _isInitializing = true; // Add initialization state

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        // Check if we're on a secure context for web
        final isSecureContext =
            Uri.base.scheme == 'https' ||
            Uri.base.host == 'localhost' ||
            Uri.base.host == '127.0.0.1';

        if (!isSecureContext) {
          setState(() {
            _hasPermission = false;
            _isInitializing = false;
            _errorMessage =
                'Camera access requires HTTPS or localhost.\n\n'
                'Current URL: ${Uri.base}\n\n'
                'Please use:\n'
                '• https://your-domain.com\n'
                '• http://localhost:port\n'
                '• http://127.0.0.1:port';
          });
          return;
        }

        // For web, try to create and start the controller
        try {
          _controller = MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
            facing: CameraFacing.back,
            torchEnabled: false,
          );

          // Add a longer delay to ensure proper initialization
          await Future.delayed(const Duration(milliseconds: 2000));

          // Test if camera is actually working by checking if controller is ready
          setState(() {
            _hasPermission = true;
            _isInitializing = false;
          });
        } catch (e) {
          // If initialization fails, clean up and show error
          _controller?.dispose();
          _controller = null;
          setState(() {
            _hasPermission = false;
            _isInitializing = false;
            _errorMessage =
                'Camera initialization failed.\n\n'
                'This usually means:\n'
                '• Camera permission was denied\n'
                '• Camera is being used by another app\n'
                '• Browser doesn\'t support camera API\n\n'
                'Error: ${e.toString()}';
          });
        }
      } else {
        // For mobile, check camera permission first
        final status = await Permission.camera.request();
        if (status == PermissionStatus.granted) {
          _controller = MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
            facing: CameraFacing.back,
          );
          setState(() {
            _hasPermission = true;
            _isInitializing = false;
          });
        } else {
          setState(() {
            _hasPermission = false;
            _isInitializing = false;
            _errorMessage = 'Camera permission is required to scan barcodes';
          });
        }
      }
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _isInitializing = false;
        _errorMessage = kIsWeb
            ? 'Failed to access camera. Please check browser permissions.'
            : 'Failed to initialize camera: ${e.toString()}';
      });
      _controller?.dispose();
      _controller = null;
    }
  }

  Future<void> _processBarcode(String serialNumber) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if bot exists in registry
      final registryDoc = await FirebaseFirestore.instance
          .collection('bot_registry')
          .doc(serialNumber)
          .get();

      if (!registryDoc.exists) {
        _showErrorSnackBar(
          'Bot with serial number $serialNumber not found in registry',
        );
        return;
      }

      final registryData = registryDoc.data()!;
      final isRegistered = registryData['is_registered'] ?? false;

      if (isRegistered) {
        _showErrorSnackBar('Bot is already registered');
        return;
      }

      // Bot is valid and not registered - return serial number for registration
      if (mounted) {
        _showSuccessSnackBar('Bot verified! Proceeding to registration...');
        Navigator.pop(context, serialNumber);
      }
    } catch (e) {
      _showErrorSnackBar('Error processing barcode: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [if (_controller != null) _buildTorchButton()],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildTorchButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: ValueNotifier(_isTorchOn), // Use manual state
      builder: (context, isTorchOn, child) {
        return IconButton(
          onPressed: () async {
            await _controller?.toggleTorch();
            setState(() {
              _isTorchOn = !_isTorchOn; // Toggle manual state
            });
          },
          icon: Icon(
            isTorchOn ? Icons.flash_on : Icons.flash_off,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isInitializing) {
      return _buildInitializingScreen();
    }

    if (!_hasPermission) {
      return _buildPermissionDenied(colorScheme);
    }

    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _controller!,
          onDetect: (BarcodeCapture capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null && code.isNotEmpty && !_isProcessing) {
                _processBarcode(code);
                break;
              }
            }
          },
        ),
        _buildOverlay(),
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildInitializingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Requesting Camera Access...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? 'Your browser will ask for camera permission.\nPlease click "Allow" to continue.'
                  : 'Setting up barcode scanner',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.blue[200], size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Look for camera permission dialog in your browser address bar',
                        style: TextStyle(color: Colors.blue[200], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 80,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Access Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage ??
                      'Please grant camera permission to scan barcodes',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[300], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'How to enable camera access:',
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Look for camera icon 📷 in address bar\n'
                        '2. Click it and select "Always allow"\n'
                        '3. Or go to browser Settings > Privacy > Camera\n'
                        '4. Add this site to allowed list\n'
                        '5. Refresh this page',
                        style: TextStyle(
                          color: Colors.blue[200],
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Add a direct permission request button for web
                ElevatedButton.icon(
                  onPressed: () async {
                    // Force reload the page to trigger fresh permission request
                    if (kIsWeb) {
                      // ignore: avoid_web_libraries_in_flutter
                      // Use a different approach to request permission
                      await _initializeScanner();
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Request Camera Access'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await _initializeScanner();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: Colors.white,
          borderRadius: 16,
          borderLength: 30,
          borderWidth: 4,
          cutOutSize: 250,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Position the barcode within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The bot will be automatically registered once scanned',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verifying barcode...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path cutOutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, cutOutPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderWidthSize = borderWidth;
    final borderOffset = borderWidthSize / 2;
    final borderRadius = this.borderRadius;
    final borderLength = this.borderLength;

    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutWidth / 2 + borderOffset,
      rect.top + height / 2 - cutOutHeight / 2 + borderOffset,
      cutOutWidth - borderWidthSize,
      cutOutHeight - borderWidthSize,
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidthSize;

    final backgroundPath = Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw corners
    final left = cutOutRect.left;
    final top = cutOutRect.top;
    final right = cutOutRect.right;
    final bottom = cutOutRect.bottom;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + borderRadius)
        ..quadraticBezierTo(left, top, left + borderRadius, top)
        ..lineTo(left + borderLength, top),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left, top + borderRadius)
        ..lineTo(left, top + borderLength),
      borderPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, top)
        ..lineTo(right - borderRadius, top)
        ..quadraticBezierTo(right, top, right, top + borderRadius),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(right, top + borderRadius)
        ..lineTo(right, top + borderLength),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - borderLength)
        ..lineTo(left, bottom - borderRadius)
        ..quadraticBezierTo(left, bottom, left + borderRadius, bottom),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left + borderRadius, bottom)
        ..lineTo(left + borderLength, bottom),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, bottom)
        ..lineTo(right - borderRadius, bottom)
        ..quadraticBezierTo(right, bottom, right, bottom - borderRadius),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - borderRadius)
        ..lineTo(right, bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
