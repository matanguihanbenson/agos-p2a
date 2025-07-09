import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showActiveOnly = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Management',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            Text(
              'Field Operators',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Users'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'refresh') {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Admin Action Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUserDialog(context),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Add Field Operator'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          _buildSearchAndFilters(theme, colorScheme),
          Expanded(child: _buildUsersList(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Search & Filter',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          FilterChip(
            label: const Text('Active Only'),
            selected: _showActiveOnly,
            onSelected: (selected) =>
                setState(() => _showActiveOnly = selected),
            selectedColor: colorScheme.primaryContainer,
            checkmarkColor: colorScheme.onPrimaryContainer,
            backgroundColor: colorScheme.surface,
            side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('created_by_admin', isNotEqualTo: '')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildEmptyState(
            colorScheme,
            Icons.error_outline_rounded,
            'Permission Error',
            'Unable to access user data',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = '${data['firstname']} ${data['lastname']}'.toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();
          final isActive = data['isActive'] ?? true;

          bool matchesSearch =
              _searchQuery.isEmpty ||
              name.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase());

          bool matchesActive = !_showActiveOnly || isActive;

          return matchesSearch && matchesActive;
        }).toList();

        if (users.isEmpty) {
          return _buildEmptyState(
            colorScheme,
            Icons.people_outline_rounded,
            'No field operators found',
            _searchQuery.isNotEmpty || _showActiveOnly
                ? 'Try adjusting your search or filter criteria'
                : 'You haven\'t created any field operators yet',
          );
        }

        // Always use list view
        return _buildListView(users, colorScheme);
      },
    );
  }

  Widget _buildEmptyState(
    ColorScheme colorScheme,
    IconData icon,
    String message,
    String subMessage,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    List<QueryDocumentSnapshot> users,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Field Operators (${users.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: users.length,
              separatorBuilder: (context, index) => Divider(
                color: colorScheme.outline.withOpacity(0.2),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final doc = users[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildUserListTile(doc, data, colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUserDialog(context, doc),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    radius: 18,
                    child: Text(
                      (data['firstname']?[0] ?? '').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusIndicator(data['isActive'] ?? true, colorScheme),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${data['firstname'] ?? ''} ${data['lastname'] ?? ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                data['email'] ?? '',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Field Operator',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserListTile(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    ColorScheme colorScheme,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary,
        radius: 18,
        child: Text(
          (data['firstname']?[0] ?? '').toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        '${data['firstname'] ?? ''} ${data['lastname'] ?? ''}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['email'] ?? '',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Field Operator',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
              if (data['organization'] != null &&
                  data['organization'].toString().isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['organization'],
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIndicator(data['isActive'] ?? true, colorScheme),
          const SizedBox(width: 8),
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      data['isActive'] == true
                          ? Icons.block
                          : Icons.check_circle,
                      color: data['isActive'] == true
                          ? Colors.orange
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(data['isActive'] == true ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showUserDialog(context, doc);
                  break;
                case 'toggle':
                  _toggleUserStatus(doc.id, !(data['isActive'] ?? true));
                  break;
              }
            },
          ),
        ],
      ),
      onTap: () => _showUserDialog(context, doc),
    );
  }

  Widget _buildStatusIndicator(bool isActive, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating user status: $e')));
    }
  }

  void _showUserDialog(BuildContext context, [DocumentSnapshot? userDoc]) {
    final isEditing = userDoc != null;
    final userData = isEditing
        ? userDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};

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
                isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(isEditing ? 'Edit Field Operator' : 'Add Field Operator'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Field operators are users who operate bots in the field.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                // Prevent double tap by disabling the button after first tap
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

                // Get current admin's ID
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: No authenticated admin user'),
                    ),
                  );
                  setState(() => _isSubmitting = false);
                  return;
                }

                final userData = {
                  'firstname': firstNameController.text,
                  'lastname': lastNameController.text,
                  'email': emailController.text,
                  'organization': organizationController.text,
                  'role': 'field_operator', // Auto-assigned role
                  'ecoPoints': 0, // Default value
                  'isActive': isActive,
                  'badges': [], // Default empty array
                  'updated_at': FieldValue.serverTimestamp(),
                  'created_by_admin': currentUser.uid, // Use actual admin ID
                };

                if (!isEditing) {
                  userData['created_at'] = FieldValue.serverTimestamp();
                }

                try {
                  if (isEditing) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userDoc.id)
                        .update(userData);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .add(userData);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Field operator ${isEditing ? 'updated' : 'created'} successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error ${isEditing ? 'updating' : 'creating'} field operator: $e',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
