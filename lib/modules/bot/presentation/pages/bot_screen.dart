import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/user_providers.dart';

import '../widgets/bot_search_and_filter.dart';
import '../widgets/bot_list_view.dart';
import '../widgets/bot_grid_view.dart';
import '../widgets/bot_empty_state.dart';
import '../widgets/bot_card.dart';
import 'add_bot.dart';
import 'assign_bot.dart';
import 'reassign_bot.dart';

class BotScreen extends ConsumerStatefulWidget {
  final String? role; // Optional

  const BotScreen({super.key, this.role});

  @override
  ConsumerState<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends ConsumerState<BotScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'All';
  bool _isGridView = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userRoleAsync = ref.watch(userRoleProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final createdByAdminAsync = ref.watch(createdByAdminProvider);

    return userRoleAsync.when(
      data: (userRole) {
        if (currentUserId == null) {
          return BotEmptyState(
            icon: Icons.person_off_outlined,
            message: 'Please log in to access bot management',
          );
        }
        return createdByAdminAsync.when(
          data: (createdByAdmin) => _buildScreenContent(
            context,
            theme,
            colorScheme,
            userRole,
            currentUserId,
            createdByAdmin,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildScreenContent(
            context,
            theme,
            colorScheme,
            userRole,
            currentUserId,
            null,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => BotEmptyState(
        icon: Icons.error_outline,
        message: 'Error loading user role',
        subMessage: 'Using default permissions',
      ),
    );
  }

  Widget _buildScreenContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String userRole,
    String userId,
    String? createdByAdmin,
  ) {
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
              'Bot Management',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            Text(
              userRole == 'admin'
                  ? 'My Bots'
                  : createdByAdmin != null
                  ? 'My Assigned Bots'
                  : 'My Bots',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          // Grid/List Toggle
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _isGridView
                  ? colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: _isGridView
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.7),
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'List View' : 'Grid View',
            ),
          ),
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
              if (userRole == 'admin')
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              if (value == 'refresh') {
                setState(() {});
              }
              // TODO: Handle other menu actions as needed
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Admin Action Buttons Section
          if (userRole == 'admin')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddBotScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Bot'),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AssignBotScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Assign Bot'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReassignBotScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Reassign'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          BotSearchAndFilter(
            searchCtrl: _searchCtrl,
            statusFilter: _statusFilter,
            onSearchChanged: () => setState(() {}),
            onFilterChanged: (filter) => setState(() => _statusFilter = filter),
            userRole: userRole,
          ),
          Expanded(
            child: BotListOrGrid(
              isGridView: _isGridView,
              userRole: userRole,
              userId: userId,
              createdByAdmin: createdByAdmin,
              statusFilter: _statusFilter,
              searchCtrl: _searchCtrl,
            ),
          ),
        ],
      ),
    );
  }
}

// Modularized list/grid switcher for bot views
class BotListOrGrid extends StatefulWidget {
  final bool isGridView;
  final String userRole;
  final String userId;
  final String? createdByAdmin;
  final String statusFilter;
  final TextEditingController searchCtrl;

  const BotListOrGrid({
    super.key,
    required this.isGridView,
    required this.userRole,
    required this.userId,
    required this.createdByAdmin,
    required this.statusFilter,
    required this.searchCtrl,
  });

  @override
  State<BotListOrGrid> createState() => _BotListOrGridState();
}

class _BotListOrGridState extends State<BotListOrGrid> {
  final rtdb.DatabaseReference _database = rtdb.FirebaseDatabase.instance.ref();
  Map<String, Map<String, dynamic>> _realtimeData = {};

  @override
  void initState() {
    super.initState();
    _subscribeToRealtimeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _subscribeToRealtimeData() {
    _database.child('bots').onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          setState(() {
            _realtimeData = data.map(
              (key, value) =>
                  MapEntry(key.toString(), Map<String, dynamic>.from(value)),
            );
          });
        }
      }
    });
  }

  Stream<QuerySnapshot> _getBotStream() {
    final firestore = FirebaseFirestore.instance;
    Query<Map<String, dynamic>> query;

    if (widget.userRole == 'admin') {
      query = firestore
          .collection('bots')
          .where('owner_admin_id', isEqualTo: widget.userId);
    } else {
      query = firestore
          .collection('bots')
          .where('assigned_to', isEqualTo: widget.userId);
    }
    return query.snapshots(includeMetadataChanges: true);
  }

  bool _matchesFilter(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final nameField = (data['name'] as String?)?.toLowerCase() ?? '';
    final idLower = doc.id.toLowerCase();
    final searchQuery = widget.searchCtrl.text.trim().toLowerCase();

    // Search filter
    if (searchQuery.isNotEmpty &&
        !(nameField.contains(searchQuery) || idLower.contains(searchQuery))) {
      return false;
    }

    // Status filter - check real-time data first, then fallback to Firestore
    final realtimeBot = _realtimeData[doc.id];
    final status = (realtimeBot?['status'] ?? data['status'] ?? '')
        .toString()
        .toLowerCase();
    final active = realtimeBot?['active'] ?? data['active'] ?? false;

    switch (widget.statusFilter) {
      case 'deployed':
      case 'returned':
        return status == widget.statusFilter;
      case 'active':
        return active;
      case 'inactive':
        return !active;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBotStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return BotEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Permission Error',
            subMessage: widget.userRole == 'admin'
                ? 'Unable to access bot data'
                : 'Unable to access your assigned bots',
          );
        }
        final docs = (snap.data?.docs ?? []).where(_matchesFilter).toList();

        final filteredDocs = docs;

        if (filteredDocs.isEmpty) {
          return BotEmptyState(
            icon: Icons.directions_boat_rounded,
            message: 'No bots found',
            subMessage:
                widget.searchCtrl.text.isNotEmpty ||
                    widget.statusFilter != 'All'
                ? 'Try adjusting your search or filter criteria'
                : widget.userRole == 'admin'
                ? 'You haven\'t created any bots yet'
                : 'No bots have been assigned to you yet',
          );
        }
        if (widget.isGridView) {
          return BotGridView(bots: filteredDocs);
        } else {
          return BotListView(bots: filteredDocs);
        }
      },
    );
  }
}
