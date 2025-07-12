import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserActions extends StatelessWidget {
  final DocumentSnapshot? botDoc;

  const UserActions({Key? key, this.botDoc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
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
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feat) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feat coming soon')));
  }
}
