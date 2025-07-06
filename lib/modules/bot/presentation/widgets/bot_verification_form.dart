import 'package:flutter/material.dart';

class BotVerificationForm extends StatelessWidget {
  final TextEditingController serialNumberController;
  final bool isVerifying;
  final VoidCallback onVerify;
  final VoidCallback onScanBarcode;

  const BotVerificationForm({
    super.key,
    required this.serialNumberController,
    required this.isVerifying,
    required this.onVerify,
    required this.onScanBarcode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (as before)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Bot Verification',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Scan barcode or enter serial number to verify bot',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Barcode scan option (as before)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.qr_code_scanner, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Scan Barcode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point camera at bot barcode',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onScanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Barcode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // OR Divider (as before)
        Row(
          children: [
            Expanded(
              child: Divider(color: colorScheme.outline.withOpacity(0.3)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            Expanded(
              child: Divider(color: colorScheme.outline.withOpacity(0.3)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Manual serial input (as before)
        Text(
          'Enter Serial Number',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: serialNumberController,
          decoration: InputDecoration(
            labelText: 'Serial Number',
            hintText: 'Enter bot serial number',
            prefixIcon: const Icon(Icons.numbers),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Verify button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isVerifying ? null : onVerify,
            icon: isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.verified_outlined),
            label: Text(isVerifying ? 'Verifying...' : 'Verify Bot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
