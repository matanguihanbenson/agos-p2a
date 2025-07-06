import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActions extends StatelessWidget {
  final DocumentReference docRef;
  final String? assignedTo;

  const AdminActions({Key? key, required this.docRef, this.assignedTo})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _editBot(context),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Bot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _assignOrUnassign(context),
                icon: Icon(
                  assignedTo != null ? Icons.person_remove : Icons.person_add,
                  size: 18,
                ),
                label: Text(assignedTo != null ? 'Reassign' : 'Assign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.onSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
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
        ),
      ],
    );
  }

  void _editBot(BuildContext context) async {
    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists) return;
      final data = docSnap.data() as Map<String, dynamic>;
      final controller = TextEditingController(
        text: data['name']?.toString() ?? '',
      );
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Edit Bot Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Bot Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await docRef.update({
                    'name': controller.text.trim(),
                    'updated_at': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bot updated successfully')),
                    );
                  }
                } catch (_) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update bot')),
                    );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading bot data')));
    }
  }

  void _assignOrUnassign(BuildContext context) async {
    try {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(assignedTo != null ? 'Manage Assignment' : 'Assign Bot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (assignedTo != null) ...[
                const Text('Current assignment will be removed.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await docRef.update({
                        'assigned_to': FieldValue.delete(),
                        'updated_at': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bot unassigned successfully'),
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to unassign bot'),
                          ),
                        );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Remove Assignment'),
                ),
              ] else ...[
                const Text('Assignment feature coming soon'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error managing assignment')),
      );
    }
  }

  void _showComingSoon(BuildContext context, String feat) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feat coming soon')));
  }
}
