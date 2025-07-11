import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserActions extends StatelessWidget {
  final DocumentSnapshot? botDoc;

  const UserActions({Key? key, this.botDoc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (botDoc != null) {
                Navigator.pushNamed(context, '/live-feed', arguments: botDoc);
              } else {
                _showComingSoon(context, 'Live Feed');
              }
            },
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
