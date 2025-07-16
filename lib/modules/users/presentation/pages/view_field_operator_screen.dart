import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewFieldOperatorScreen extends StatefulWidget {
  final DocumentSnapshot userDoc;

  const ViewFieldOperatorScreen({super.key, required this.userDoc});

  @override
  State<ViewFieldOperatorScreen> createState() =>
      _ViewFieldOperatorScreenState();
}

class _ViewFieldOperatorScreenState extends State<ViewFieldOperatorScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDoc.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: colorScheme.background,
            foregroundColor: colorScheme.onBackground,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Field Operator Details',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(userData, colorScheme),
                      const SizedBox(height: 12),
                      _buildPersonalInfoCard(userData, colorScheme),
                      const SizedBox(height: 12),
                      _buildStatusCard(userData, colorScheme),
                      const SizedBox(height: 12),
                      _buildSystemInfoCard(userData, colorScheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/edit-field-operator',
                        arguments: widget.userDoc,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showToggleStatusConfirmation(
                        context,
                        !(userData['isActive'] ?? true),
                        userData,
                      ),
                      icon: Icon(
                        userData['isActive'] == true
                            ? Icons.block
                            : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(
                        userData['isActive'] == true
                            ? 'Deactivate'
                            : 'Activate',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: userData['isActive'] == true
                            ? Colors.orange
                            : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(
    Map<String, dynamic> userData,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                radius: 32,
                child: Text(
                  (userData['firstname']?[0] ?? '').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                ),
                child: Text(
                  'Field Operator',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusIndicator(userData['isActive'] ?? true, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(
    Map<String, dynamic> userData,
    ColorScheme colorScheme,
  ) {
    return Card(
      color: colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.email,
              'Email',
              userData['email'] ?? 'Not provided',
              colorScheme,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.business,
              'Organization',
              userData['organization'] ?? 'Not specified',
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    Map<String, dynamic> userData,
    ColorScheme colorScheme,
  ) {
    final isActive = userData['isActive'] ?? true;
    return Card(
      color: colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Account Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.08)
                    : Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'User can operate bots and access the system'
                        : 'User cannot access the system',
                    style: TextStyle(
                      color: isActive
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      fontSize: 11,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard(
    Map<String, dynamic> userData,
    ColorScheme colorScheme,
  ) {
    final createdAt = userData['created_at'] as Timestamp?;
    final updatedAt = userData['updated_at'] as Timestamp?;

    return Card(
      color: colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'System Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Created',
              createdAt != null
                  ? _formatDateTime(createdAt.toDate())
                  : 'Unknown',
              colorScheme,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.update,
              'Last Updated',
              updatedAt != null ? _formatDateTime(updatedAt.toDate()) : 'Never',
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(bool isActive, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleUserStatus(bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDoc.id)
          .update({
            'isActive': isActive,
            'updated_at': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${isActive ? 'activated' : 'deactivated'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditDialog(BuildContext context) {
    final userData = widget.userDoc.data() as Map<String, dynamic>;

    final firstNameController = TextEditingController(
      text: userData['firstname'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: userData['lastname'] ?? '',
    );
    final emailController = TextEditingController(
      text: userData['email'] ?? '',
    );
    final organizationController = TextEditingController(
      text: userData['organization'] ?? '',
    );

    bool isActive = userData['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Edit Field Operator'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: organizationController,
                    decoration: InputDecoration(
                      labelText: 'Organization (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    child: SwitchListTile(
                      title: const Text('Active Status'),
                      subtitle: Text(
                        isActive ? 'User can operate bots' : 'User is inactive',
                      ),
                      value: isActive,
                      onChanged: (value) =>
                          setDialogState(() => isActive = value),
                      secondary: Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_isSubmitting) return;
                setState(() => _isSubmitting = true);

                if (firstNameController.text.isEmpty ||
                    emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in required fields'),
                    ),
                  );
                  setState(() => _isSubmitting = false);
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userDoc.id)
                      .update({
                        'firstname': firstNameController.text,
                        'lastname': lastNameController.text,
                        'email': emailController.text,
                        'organization': organizationController.text,
                        'isActive': isActive,
                        'updated_at': FieldValue.serverTimestamp(),
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Field operator updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating field operator: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showToggleStatusConfirmation(
    BuildContext context,
    bool newStatus,
    Map<String, dynamic> userData,
  ) {
    final action = newStatus ? 'activate' : 'deactivate';
    final userName =
        '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Icon(
              newStatus ? Icons.check_circle : Icons.warning,
              color: newStatus ? Colors.green : Colors.orange,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              '${action[0].toUpperCase()}${action.substring(1)} User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to $action this user?',
              style: const TextStyle(letterSpacing: 0.1),
            ),
            const SizedBox(height: 8),
            if (userName.isNotEmpty) ...[
              Text(
                'User: $userName',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              newStatus
                  ? 'The user will be able to operate bots and access the system.'
                  : 'The user will lose access to the system and cannot operate bots.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(letterSpacing: 0.2)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleUserStatus(newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              action.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
