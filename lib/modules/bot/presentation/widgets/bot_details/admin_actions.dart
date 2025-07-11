import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminActions extends StatelessWidget {
  final DocumentReference docRef;
  final String? assignedTo;
  final DocumentSnapshot? botDoc;

  const AdminActions({
    Key? key,
    required this.docRef,
    this.assignedTo,
    this.botDoc,
  }) : super(key: key);

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
                onPressed: () {
                  if (botDoc != null) {
                    Navigator.pushNamed(
                      context,
                      '/live-feed',
                      arguments: botDoc,
                    );
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
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                assignedTo != null ? Icons.swap_horiz : Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assignedTo != null ? 'Manage Assignment' : 'Assign Bot',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assignedTo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currently Assigned',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[800],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You can remove the current assignment or reassign to a different operator.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showUnassignConfirmation(context),
                      icon: const Icon(Icons.person_remove, size: 16),
                      label: const Text(
                        'Remove Assignment',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reassign to Different Operator',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assignment_ind,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assign Bot to Operator',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select an operator from the list below to assign this bot.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Available Operators',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _UserSelectionList(
                      onUserSelected: (userId, userName) =>
                          _showAssignConfirmation(context, userId, userName),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
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

  void _showUnassignConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Remove Assignment', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove the current assignment? The operator will no longer have access to this bot.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await _performUnassignment(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAssignConfirmation(
    BuildContext context,
    String userId,
    String userName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.assignment_ind,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Confirm Assignment', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
            children: [
              const TextSpan(
                text: 'Are you sure you want to assign this bot to ',
              ),
              TextSpan(
                text: userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await _performAssignment(context, userId, userName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _performUnassignment(BuildContext context) async {
    try {
      await docRef.update({
        'assigned_to': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Bot unassigned successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to unassign bot'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performAssignment(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    try {
      await docRef.update({
        'assigned_to': userId,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Bot assigned to $userName successfully')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to assign bot'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context, String feat) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feat coming soon')));
  }
}

class _UserSelectionList extends StatelessWidget {
  final Function(String userId, String userName) onUserSelected;

  const _UserSelectionList({required this.onUserSelected});

  @override
  Widget build(BuildContext context) {
    final currentAdminId = FirebaseAuth.instance.currentUser?.uid;

    if (currentAdminId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 8),
            Text('Admin not authenticated'),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('created_by_admin', isEqualTo: currentAdminId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error loading users: ${snapshot.error}');
          // Fallback query
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, fallbackSnapshot) {
              if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (fallbackSnapshot.hasError) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 8),
                    const Text('Error loading operators'),
                    const SizedBox(height: 4),
                    Text(
                      'Error: ${fallbackSnapshot.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }

              final allUsers = fallbackSnapshot.data?.docs ?? [];
              final filteredUsers = allUsers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['created_by_admin'] == currentAdminId;
              }).toList();

              return _buildUserList(context, filteredUsers);
            },
          );
        }

        final users = snapshot.data?.docs ?? [];
        return _buildUserList(context, users);
      },
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<QueryDocumentSnapshot> users,
  ) {
    if (users.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Operators Found',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create operator accounts first to assign bots.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: users.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey[300]),
      itemBuilder: (context, index) {
        final user = users[index];
        final userData = user.data() as Map<String, dynamic>;
        final firstName = userData['firstname'] ?? '';
        final lastName = userData['lastname'] ?? '';
        final userName = '${firstName} ${lastName}'.trim();
        final displayName = userName.isNotEmpty ? userName : 'Unknown User';
        final userEmail = userData['email'] ?? '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
            title: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            subtitle: Text(
              userEmail,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            onTap: () => onUserSelected(user.id, displayName),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ),
        );
      },
    );
  }
}
