import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/user_providers.dart';
import '../widgets/bot_verification_form.dart';
import '../widgets/bot_registration_form.dart';
import 'barcode_scanner_screen.dart';

class AddBotScreen extends ConsumerStatefulWidget {
  const AddBotScreen({super.key});

  @override
  ConsumerState<AddBotScreen> createState() => _AddBotScreenState();
}

class _AddBotScreenState extends ConsumerState<AddBotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizationController =
      TextEditingController(); // Add organization controller

  bool _isVerifying = false;
  bool _isRegistering = false;

  // Bot verification states
  bool _isBotVerified = false;
  String? _verifiedBotId;
  Map<String, dynamic>? _botRegistryData;

  @override
  void dispose() {
    _serialNumberController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _organizationController.dispose(); // Dispose organization controller
    super.dispose();
  }

  // --- BOT VERIFICATION LOGIC ---
  Future<void> _verifyBot() async {
    if (_serialNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a serial number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final serialNumber = _serialNumberController.text.trim();

      final docRef = FirebaseFirestore.instance
          .collection('bot_registry')
          .doc(serialNumber);

      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid serial number'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = docSnapshot.data() ?? {};
      final isRegistered = data['is_registered'] ?? false;

      if (isRegistered == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bot already registered'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _isBotVerified = true;
        _verifiedBotId = docSnapshot.id;
        _botRegistryData = data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to bot!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying bot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  // --- BOT REGISTRATION LOGIC ---
  Future<void> _registerBot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not logged in');

      final botId = _serialNumberController.text.trim();

      final botData = {
        'bot_id': botId,
        'name': _nameController.text.trim().isEmpty
            ? 'Unnamed Bot'
            : _nameController.text.trim(),
        'notes': _descriptionController.text.trim(),
        'owner_admin_id': userId,
        'assigned_to': null,
        'organization': _organizationController.text.trim().isEmpty
            ? 'Divine Word College of Calapan'
            : _organizationController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final batch = FirebaseFirestore.instance.batch();

      // Use the serial number as the document ID in 'bots'
      final botRef = FirebaseFirestore.instance.collection('bots').doc(botId);
      batch.set(botRef, botData);

      // Update bot_registry to mark as registered
      final registryRef = FirebaseFirestore.instance
          .collection('bot_registry')
          .doc(botId);
      batch.update(registryRef, {
        'is_registered': true,
        'registered_at': FieldValue.serverTimestamp(),
        'registered_by': userId,
        'bot_id': botId,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bot "${_nameController.text}" registered successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back after registration
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering bot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  // Barcode scan handling
  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      if (result != null && mounted) {
        // Set the scanned serial number and verify the bot
        _serialNumberController.text = result;
        await _verifyBot();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening barcode scanner: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _resetVerification() {
    setState(() {
      _isBotVerified = false;
      _verifiedBotId = null;
      _botRegistryData = null;
      _serialNumberController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        title: Text(
          _isBotVerified ? 'Register Bot' : 'Add New Bot',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          if (_isBotVerified)
            TextButton(
              onPressed: _isRegistering ? null : _registerBot,
              child: _isRegistering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isBotVerified
            ? BotRegistrationForm(
                formKey: _formKey,
                nameController: _nameController,
                descriptionController: _descriptionController,
                organizationController:
                    _organizationController, // Add organization controller
                serialNumber: _serialNumberController.text,
                isRegistering: _isRegistering,
                onRegister: _registerBot,
                onChangeSerial: _resetVerification,
              )
            : BotVerificationForm(
                serialNumberController: _serialNumberController,
                isVerifying: _isVerifying,
                onVerify: _verifyBot,
                onScanBarcode: _scanBarcode,
              ),
      ),
    );
  }
}
