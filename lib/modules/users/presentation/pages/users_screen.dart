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
  bool _showInactiveOnly = false;

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
        title: const Text('Users Management'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
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
                onPressed: () =>
                    Navigator.pushNamed(context, '/add-field-operator'),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Active Only'),
                selected: _showActiveOnly,
                onSelected: (selected) {
                  setState(() {
                    _showActiveOnly = selected;
                    if (selected) _showInactiveOnly = false;
                  });
                },
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.onPrimaryContainer,
                backgroundColor: colorScheme.surface,
                side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              FilterChip(
                label: const Text('Inactive Only'),
                selected: _showInactiveOnly,
                onSelected: (selected) {
                  setState(() {
                    _showInactiveOnly = selected;
                    if (selected) _showActiveOnly = false;
                  });
                },
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange.shade700,
                backgroundColor: colorScheme.surface,
                side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(ColorScheme colorScheme) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _buildEmptyState(
        colorScheme,
        Icons.error_outline_rounded,
        'Authentication Error',
        'No admin user is currently logged in',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('created_by_admin', isEqualTo: currentUser.uid)
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

          bool matchesActiveFilter = true;
          if (_showActiveOnly) {
            matchesActiveFilter = isActive;
          } else if (_showInactiveOnly) {
            matchesActiveFilter = !isActive;
          }

          return matchesSearch && matchesActiveFilter;
        }).toList();

        if (users.isEmpty) {
          return _buildEmptyState(
            colorScheme,
            Icons.people_outline_rounded,
            'No field operators found',
            _searchQuery.isNotEmpty || _showActiveOnly || _showInactiveOnly
                ? 'Try adjusting your search or filter criteria'
                : 'You haven\'t created any field operators yet',
          );
        }

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
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: colorScheme.primary,
              size: 20,
            ),
            onPressed: () => Navigator.pushNamed(
              context,
              '/edit-field-operator',
              arguments: doc,
            ),
            tooltip: 'Edit Field Operator',
          ),
        ],
      ),
      onTap: () =>
          Navigator.pushNamed(context, '/view-field-operator', arguments: doc),
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
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user status: $e')),
        );
      }
    }
  }
}
