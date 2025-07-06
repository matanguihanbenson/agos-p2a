import 'package:flutter/material.dart';

class UserActions extends StatelessWidget {
  const UserActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showComingSoon(context, 'Live Feed'),
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text('Live Feed'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showComingSoon(context, 'Control'),
            icon: const Icon(Icons.settings_remote_rounded, size: 18),
            label: const Text('Control'),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feat) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feat coming soon')));
  }
}
