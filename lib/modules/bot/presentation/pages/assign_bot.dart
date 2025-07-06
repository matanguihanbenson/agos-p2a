import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_providers.dart';

class AssignBotScreen extends ConsumerStatefulWidget {
  const AssignBotScreen({super.key});

  @override
  ConsumerState<AssignBotScreen> createState() => _AssignBotScreenState();
}

class _AssignBotScreenState extends ConsumerState<AssignBotScreen> {
  String? selectedUserId;
  final Set<String> selectedBotIds = {};
  bool isLoading = false;
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _botSearchController = TextEditingController();
  String userSearchQuery = '';
  String botSearchQuery = '';

  @override
  void dispose() {
    _userSearchController.dispose();
    _botSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assign Bot'), centerTitle: true),
        body: const Center(child: Text('Please log in to assign bots')),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        title: const Text(
          'Assign Bot',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (selectedUserId != null && selectedBotIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${selectedBotIds.length}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // User Selection Section
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Card(
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                          'Select Field Operator',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // User Search Bar
                    TextField(
                      controller: _userSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search operators...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          userSearchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // User List
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('created_by_admin', isEqualTo: currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return _errorMessage('Error loading users');
                        }

                        final allDocs = snapshot.data?.docs ?? [];
                        final users = allDocs.where((user) {
                          final userData = user.data() as Map<String, dynamic>;
                          final firstName = userData['firstname'] ?? '';
                          final lastName = userData['lastname'] ?? '';
                          final name = (firstName + ' ' + lastName).trim();
                          final email = userData['email'] ?? '';
                          return userSearchQuery.isEmpty ||
                              name.toLowerCase().contains(userSearchQuery) ||
                              email.toLowerCase().contains(userSearchQuery);
                        }).toList();

                        if (users.isEmpty) {
                          return _errorMessage(
                            userSearchQuery.isNotEmpty
                                ? 'No users match your search'
                                : 'No users found',
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: users.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final userData =
                                  user.data() as Map<String, dynamic>;
                              final firstName = userData['firstname'] ?? '';
                              final lastName = userData['lastname'] ?? '';
                              final name =
                                  (firstName + ' ' + lastName).trim().isEmpty
                                  ? 'Unknown'
                                  : (firstName + ' ' + lastName).trim();
                              final email = userData['email'] ?? '';
                              final isSelected = selectedUserId == user.id;

                              return Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary.withOpacity(0.1)
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline.withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.primary.withOpacity(0.1),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: email.isNotEmpty
                                      ? Text(
                                          email,
                                          style: TextStyle(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: colorScheme.primary,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      selectedUserId = user.id;
                                      selectedBotIds.clear();
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Available Bots Section
          if (selectedUserId != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Bots',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (selectedBotIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${selectedBotIds.length} selected',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bot Search Bar
                    TextField(
                      controller: _botSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search bots...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          botSearchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Bot List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bots')
                            .where('owner_admin_id', isEqualTo: currentUserId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return _errorMessage('Error loading bots');
                          }

                          final allBots = snapshot.data?.docs ?? [];
                          final availableBots = allBots.where((bot) {
                            final botData = bot.data() as Map<String, dynamic>;
                            final assignedTo = botData['assigned_to'];
                            final botName = (botData['name'] ?? '')
                                .toLowerCase();
                            final botId = bot.id.toLowerCase();
                            final matchesSearch =
                                botSearchQuery.isEmpty ||
                                botName.contains(botSearchQuery) ||
                                botId.contains(botSearchQuery);
                            return (assignedTo == null || assignedTo == '') &&
                                matchesSearch;
                          }).toList();

                          if (availableBots.isEmpty) {
                            return _emptyState(
                              icon: Icons.smart_toy_outlined,
                              title: botSearchQuery.isNotEmpty
                                  ? 'No bots found'
                                  : 'No available bots',
                              subtitle: botSearchQuery.isNotEmpty
                                  ? 'Try adjusting your search'
                                  : allBots.isEmpty
                                  ? 'You haven\'t created any bots yet'
                                  : 'All bots are currently assigned',
                            );
                          }

                          return ListView.separated(
                            itemCount: availableBots.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final bot = availableBots[index];
                              final botData =
                                  bot.data() as Map<String, dynamic>;
                              final isSelected = selectedBotIds.contains(
                                bot.id,
                              );
                              final isActive = botData['active'] ?? false;
                              final status = botData['status'] ?? 'Unknown';

                              return Card(
                                elevation: 0,
                                color: isSelected
                                    ? colorScheme.primary.withOpacity(0.08)
                                    : colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline.withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.smart_toy_rounded,
                                      color: isActive
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    botData['name'] ?? 'Bot ${bot.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${bot.id}',
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _statusChip(status, colorScheme),
                                          const SizedBox(width: 8),
                                          _statusChip(
                                            isActive ? 'Active' : 'Inactive',
                                            colorScheme,
                                            color: isActive
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.outline.withOpacity(
                                                0.5,
                                              ),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: colorScheme.onPrimary,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (selectedBotIds.contains(bot.id)) {
                                        selectedBotIds.remove(bot.id);
                                      } else {
                                        selectedBotIds.add(bot.id);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Bottom Assign Button
      bottomNavigationBar: selectedUserId != null && selectedBotIds.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _assignBots,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Assign Bots',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _errorMessage(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _statusChip(String status, ColorScheme colorScheme, {Color? color}) {
    final chipColor = color ?? _getStatusColor(status, colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'deployed':
        return Colors.green;
      case 'recalled':
        return Colors.orange;
      case 'maintenance':
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }

  Future<void> _assignBots() async {
    if (selectedUserId == null || selectedBotIds.isEmpty) return;

    setState(() => isLoading = true);

    final colorScheme = Theme.of(context).colorScheme;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final botId in selectedBotIds) {
        final botRef = FirebaseFirestore.instance.collection('bots').doc(botId);
        batch.update(botRef, {
          'assigned_to': selectedUserId,
          'assigned_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(selectedUserId)
            .get();
        final userData = userDoc.data();
        final firstName = userData?['firstname'] ?? '';
        final lastName = userData?['lastname'] ?? '';
        final userName = (firstName + ' ' + lastName).trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully assigned ${selectedBotIds.length} bot(s) to ${userName.isEmpty ? 'user' : userName}',
            ),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning bots: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
