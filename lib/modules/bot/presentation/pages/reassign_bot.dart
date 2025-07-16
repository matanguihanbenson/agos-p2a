import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_providers.dart';

class ReassignBotScreen extends ConsumerStatefulWidget {
  const ReassignBotScreen({super.key});

  @override
  ConsumerState<ReassignBotScreen> createState() => _ReassignBotScreenState();
}

class _ReassignBotScreenState extends ConsumerState<ReassignBotScreen> {
  String? selectedBotId;
  String? selectedNewUserId;
  bool isLoading = false;
  final TextEditingController _botSearchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  String botSearchQuery = '';
  String userSearchQuery = '';

  @override
  void dispose() {
    _botSearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reassign Bot'), centerTitle: true),
        body: const Center(child: Text('Please log in to reassign bots')),
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
          'Reassign Bot',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Assigned Bots Selection Section
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
                          Icons.directions_boat,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Select Bot to Reassign',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bot Search Bar
                    TextField(
                      controller: _botSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search assigned bots...',
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
                    // Assigned Bots List
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bots')
                          .where('owner_admin_id', isEqualTo: currentUserId)
                          .where('assigned_to', isNotEqualTo: null)
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
                          return _errorMessage('Error loading assigned bots');
                        }

                        final allBots = snapshot.data?.docs ?? [];
                        final filteredBots = allBots.where((bot) {
                          final botData = bot.data() as Map<String, dynamic>;
                          final botName = (botData['name'] ?? '').toLowerCase();
                          final botId = bot.id.toLowerCase();
                          final assignedTo = botData['assigned_to'];
                          return assignedTo != null &&
                              assignedTo.toString().isNotEmpty &&
                              (botSearchQuery.isEmpty ||
                                  botName.contains(botSearchQuery) ||
                                  botId.contains(botSearchQuery));
                        }).toList();

                        if (filteredBots.isEmpty) {
                          return _errorMessage(
                            botSearchQuery.isNotEmpty
                                ? 'No assigned bots match your search'
                                : 'No bots are currently assigned',
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredBots.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final bot = filteredBots[index];
                              final botData =
                                  bot.data() as Map<String, dynamic>;
                              final isSelected = selectedBotId == bot.id;
                              final assignedTo = botData['assigned_to'];

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(assignedTo)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  String assignedUserName = 'Unknown User';
                                  if (userSnapshot.hasData &&
                                      userSnapshot.data!.exists) {
                                    final userData =
                                        userSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    final firstName =
                                        userData['firstname'] ?? '';
                                    final lastName = userData['lastname'] ?? '';
                                    assignedUserName =
                                        (firstName + ' ' + lastName)
                                            .trim()
                                            .isEmpty
                                        ? 'Unknown User'
                                        : (firstName + ' ' + lastName).trim();
                                  }

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary.withOpacity(0.1)
                                          : colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.outline.withOpacity(
                                                0.2,
                                              ),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.primary.withOpacity(
                                                  0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.directions_boat,
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        botData['name'] ?? 'Bot ${bot.id}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID: ${bot.id}',
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Currently assigned to: $assignedUserName',
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle_rounded,
                                              color: colorScheme.primary,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          selectedBotId = bot.id;
                                          selectedNewUserId = null;
                                        });
                                      },
                                    ),
                                  );
                                },
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

          // New User Selection Section
          if (selectedBotId != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                          'Select New Field Operator',
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
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('created_by_admin', isEqualTo: currentUserId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return _errorMessage('Error loading users');
                          }

                          final allUsers = snapshot.data?.docs ?? [];
                          final filteredUsers = allUsers.where((user) {
                            final userData =
                                user.data() as Map<String, dynamic>;
                            final firstName = userData['firstname'] ?? '';
                            final lastName = userData['lastname'] ?? '';
                            final name = (firstName + ' ' + lastName).trim();
                            final email = userData['email'] ?? '';
                            return userSearchQuery.isEmpty ||
                                name.toLowerCase().contains(userSearchQuery) ||
                                email.toLowerCase().contains(userSearchQuery);
                          }).toList();

                          if (filteredUsers.isEmpty) {
                            return _errorMessage(
                              userSearchQuery.isNotEmpty
                                  ? 'No users match your search'
                                  : 'No users found',
                            );
                          }

                          return ListView.separated(
                            itemCount: filteredUsers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final userData =
                                  user.data() as Map<String, dynamic>;
                              final firstName = userData['firstname'] ?? '';
                              final lastName = userData['lastname'] ?? '';
                              final name =
                                  (firstName + ' ' + lastName).trim().isEmpty
                                  ? 'Unknown'
                                  : (firstName + ' ' + lastName).trim();
                              final email = userData['email'] ?? '';
                              final isSelected = selectedNewUserId == user.id;

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
                                      selectedNewUserId = user.id;
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
      // Bottom Reassign Button
      bottomNavigationBar: selectedBotId != null && selectedNewUserId != null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _reassignBot,
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
                          'Reassign Bot',
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

  Future<void> _reassignBot() async {
    if (selectedBotId == null || selectedNewUserId == null) return;

    setState(() => isLoading = true);

    final colorScheme = Theme.of(context).colorScheme;

    try {
      // Get bot and users data for confirmation message
      final botDoc = await FirebaseFirestore.instance
          .collection('bots')
          .doc(selectedBotId)
          .get();

      final newUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedNewUserId)
          .get();

      if (!botDoc.exists || !newUserDoc.exists) {
        throw Exception('Bot or user not found');
      }

      final botData = botDoc.data()!;
      final newUserData = newUserDoc.data()!;

      final botName = botData['name'] ?? 'Bot ${selectedBotId}';
      final newUserFirstName = newUserData['firstname'] ?? '';
      final newUserLastName = newUserData['lastname'] ?? '';
      final newUserName = (newUserFirstName + ' ' + newUserLastName).trim();

      // Update bot assignment
      await FirebaseFirestore.instance
          .collection('bots')
          .doc(selectedBotId)
          .update({
            'assigned_to': selectedNewUserId,
            'assigned_at': FieldValue.serverTimestamp(),
            'reassigned_at': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully reassigned "$botName" to ${newUserName.isEmpty ? 'user' : newUserName}',
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reassigning bot: $e'),
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
