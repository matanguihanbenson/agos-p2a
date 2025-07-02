import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/theme/theme.dart';

class BotScreen extends StatefulWidget {
  final String userId;
  final String role;

  const BotScreen({super.key, required this.userId, required this.role});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  String _statusFilter = 'All';
  bool _isGridView = false;
  StreamSubscription<QuerySnapshot>? _botStreamSubscription;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _botStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BotScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role || oldWidget.userId != widget.userId) {
      _botStreamSubscription?.cancel();
      setState(() {});
    }
  }

  Stream<QuerySnapshot> get _botStream {
    Query<Map<String, dynamic>> query;

    if (widget.role == 'admin') {
      query = _firestore.collection('bots');
    } else {
      query = _firestore
          .collection('bots')
          .where('assigned_to', isEqualTo: widget.userId);
    }

    // Add real-time listening with includeMetadataChanges for immediate updates
    return query.snapshots(includeMetadataChanges: true);
  }

  bool _matchesFilter(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final nameField = (data['name'] as String?)?.toLowerCase() ?? '';
    final idLower = doc.id.toLowerCase();
    final searchQuery = _searchCtrl.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty &&
        !(nameField.contains(searchQuery) || idLower.contains(searchQuery))) {
      return false;
    }

    final status = (data['status'] ?? '').toString().toLowerCase();
    final active = (data['active'] ?? false) as bool;
    switch (_statusFilter) {
      case 'deployed':
      case 'recalled':
        return status == _statusFilter;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.background,
                colorScheme.surface.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bot Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onBackground,
              ),
            ),
            Text(
              widget.role == 'admin' ? 'Admin View' : 'My Bots',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
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
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.add_rounded, color: colorScheme.primary),
              onPressed: () {
                // Add new bot functionality
              },
              tooltip: 'Add Bot',
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
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            color: colorScheme.background,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search bots by name or ID...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(color: colorScheme.onBackground),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'All',
                          'deployed',
                          'recalled',
                          'active',
                          'inactive',
                        ].map((filter) {
                          final isSelected = _statusFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(
                                filter == 'All' ? 'All' : filter.toUpperCase(),
                                style: TextStyle(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = filter),
                              backgroundColor: colorScheme.surface,
                              selectedColor: colorScheme.primary,
                              checkmarkColor: colorScheme.onPrimary,
                              side: BorderSide(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Bot list/grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              key: ValueKey('${widget.role}_${widget.userId}_$_statusFilter'),
              stream: _botStream,
              builder: (context, snap) {
                // Handle loading state
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: colorScheme.primary,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading bots...',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snap.error}',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final docs = (snap.data?.docs ?? [])
                    .where(_matchesFilter)
                    .toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_boat_rounded,
                            size: 48,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No bots found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchCtrl.text.isNotEmpty || _statusFilter != 'All'
                              ? 'Try adjusting your search or filter criteria'
                              : 'No bots have been assigned to you yet',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (_isGridView) {
                  return _buildGridView(docs);
                } else {
                  return _buildListView(docs);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<DocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, i) => _buildBotCard(docs[i], i),
    );
  }

  Widget _buildGridView(List<DocumentSnapshot> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: docs.length,
      itemBuilder: (context, i) => _buildBotCard(docs[i], i, isGrid: true),
    );
  }

  Widget _buildBotCard(DocumentSnapshot doc, int index, {bool isGrid = false}) {
    final data = doc.data()! as Map<String, dynamic>;
    final nameField = data['name'] as String?;
    final displayName = (nameField != null && nameField.isNotEmpty)
        ? nameField
        : 'Bot #${index + 1}';
    final status = data['status'] ?? 'unknown';
    final active = data['active'] == true;
    final assignedUid = data['assigned_to'] as String?;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 12),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to bot details
          },
          child: Padding(
            padding: EdgeInsets.all(isGrid ? 14 : 18),
            child: isGrid
                ? _buildGridCardContent(
                    doc,
                    index,
                    displayName,
                    status,
                    active,
                    assignedUid,
                    colorScheme,
                  )
                : _buildListCardContent(
                    doc,
                    index,
                    displayName,
                    status,
                    active,
                    assignedUid,
                    colorScheme,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCardContent(
    DocumentSnapshot doc,
    int index,
    String displayName,
    String status,
    bool active,
    String? assignedUid,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.8),
                    colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_boat_rounded,
                color: colorScheme.onPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${doc.id.length > 15 ? '${doc.id.substring(0, 15)}...' : doc.id}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? Colors.green.withOpacity(0.15)
                : colorScheme.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active
                  ? Colors.green.withOpacity(0.3)
                  : colorScheme.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            active ? 'ACTIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: active ? Colors.green : colorScheme.error,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        // Status info
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Assignment info
        assignedUid != null
            ? FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(assignedUid).get(),
                builder: (context, userSnap) {
                  String userName = assignedUid;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final userData =
                        userSnap.data!.data()! as Map<String, dynamic>;
                    userName = userData['name'] ?? assignedUid;
                  }
                  return Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              )
            : Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Unassigned',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 12),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.videocam_outlined,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.settings_remote_rounded,
                    size: 16,
                    color: colorScheme.onPrimary,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListCardContent(
    DocumentSnapshot doc,
    int index,
    String displayName,
    String status,
    bool active,
    String? assignedUid,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.8),
                    colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_boat_rounded,
                color: colorScheme.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID: ${doc.id.length > 35 ? '${doc.id.substring(0, 35)}...' : doc.id}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? Colors.green.withOpacity(0.15)
                    : colorScheme.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active
                      ? Colors.green.withOpacity(0.3)
                      : colorScheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                active ? 'ACTIVE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.green : colorScheme.error,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Status info
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Assignment info
        assignedUid != null
            ? FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(assignedUid).get(),
                builder: (context, userSnap) {
                  String userName = assignedUid;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final userData =
                        userSnap.data!.data()! as Map<String, dynamic>;
                    userName = userData['name'] ?? assignedUid;
                  }
                  return Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assigned to: $userName',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              )
            : Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Unassigned',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 18),
        // Action buttons
        Row(
          children: [
            _buildActionButton(
              icon: Icons.videocam_outlined,
              label: 'Live Feed',
              onPressed: () {},
              colorScheme: colorScheme,
            ),
            const Spacer(),
            _buildActionButton(
              icon: Icons.settings_remote_rounded,
              label: 'Control',
              onPressed: () {},
              isPrimary: true,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    return SizedBox(
      height: isCompact ? 32 : 36,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: isCompact ? 14 : 16),
              label: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 10 : 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shadowColor: colorScheme.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: isCompact ? 14 : 16),
              label: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 10 : 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withOpacity(0.7),
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
              ),
            ),
    );
  }
}
