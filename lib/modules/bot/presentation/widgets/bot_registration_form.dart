import 'package:flutter/material.dart';

class BotRegistrationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String serialNumber;
  final bool isRegistering;
  final VoidCallback onRegister;
  final VoidCallback onChangeSerial;

  const BotRegistrationForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.serialNumber,
    required this.isRegistering,
    required this.onRegister,
    required this.onChangeSerial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header (as before)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bot Verified Successfully',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Serial: $serialNumber',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onChangeSerial,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Bot Name input
          TextFormField(
            controller: nameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bot name is required';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Bot Name',
              hintText: 'Enter bot name',
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          const SizedBox(height: 16),
          // Notes / Description
          TextFormField(
            controller: descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notes',
              hintText: 'Enter any notes for this bot',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          const SizedBox(height: 32),
          // Register Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isRegistering ? null : onRegister,
              icon: isRegistering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.app_registration),
              label: Text(
                isRegistering ? 'Registering Bot...' : 'Register Bot',
              ),
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
      ),
    );
  }
}
