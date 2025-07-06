import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../pages/bot_details.dart';

class BotCard extends StatefulWidget {
  final DocumentSnapshot doc;
  final int index;
  final bool isGrid;
  final VoidCallback? onTap;
  final VoidCallback? onLiveFeed;
  final VoidCallback? onControl;

  const BotCard({
    super.key,
    required this.doc,
    required this.index,
    this.isGrid = false,
    this.onTap,
    this.onLiveFeed,
    this.onControl,
  });

  @override
  State<BotCard> createState() => _BotCardState();
}

class _BotCardState extends State<BotCard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _subscription;
  bool? _realtimeActive;
  String? _realtimeStatus;

  @override
  void initState() {
    super.initState();
    _subscribeToRealtimeData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToRealtimeData() {
    _subscription = _database.child('bots').child(widget.doc.id).onValue.listen(
      (event) {
        if (mounted && event.snapshot.exists) {
          final botData = event.snapshot.value;
          if (botData is Map) {
            final dataMap = Map<String, dynamic>.from(botData);
            setState(() {
              final activeValue = dataMap['active'];
              _realtimeActive = activeValue is bool
                  ? activeValue
                  : (activeValue == true || activeValue == 'true');
              _realtimeStatus = dataMap['status']?.toString();
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data()! as Map<String, dynamic>;
    final nameField = data['name'] as String?;
    final displayName = (nameField != null && nameField.isNotEmpty)
        ? nameField
        : 'Bot #${widget.index + 1}';

    final active = _realtimeActive ?? (data['active'] == true);
    final status = _realtimeStatus ?? data['status']?.toString() ?? 'unknown';

    final assignedUid = data['assigned_to'] as String?;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: widget.isGrid ? 0 : 12),
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
          color: _realtimeActive != null || _realtimeStatus != null
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              widget.onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BotDetailsPage(doc: widget.doc, index: widget.index),
                  ),
                );
              },
          child: Padding(
            padding: EdgeInsets.all(widget.isGrid ? 14 : 18),
            child: widget.isGrid
                ? _buildGridCardContent(
                    context,
                    displayName,
                    status,
                    active,
                    assignedUid,
                    colorScheme,
                  )
                : _buildListCardContent(
                    context,
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
    BuildContext context,
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
                    'ID: ${_shortId(widget.doc.id)}',
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
        _buildActiveStatus(active, colorScheme),
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
        _buildAssignment(
          context,
          assignedUid,
          colorScheme,
          fontSize: 11,
          iconSize: 14,
          isGrid: widget.isGrid,
        ),
        const SizedBox(height: 12),
        _buildActionButtons(colorScheme, compact: true),
      ],
    );
  }

  Widget _buildListCardContent(
    BuildContext context,
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
                    'ID: ${_shortId(widget.doc.id, 35)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildActiveStatus(active, colorScheme, horizontal: true),
          ],
        ),
        const SizedBox(height: 18),
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
        _buildAssignment(
          context,
          assignedUid,
          colorScheme,
          fontSize: 13,
          iconSize: 16,
          isGrid: widget.isGrid,
        ),
        const SizedBox(height: 18),
        _buildActionButtons(colorScheme),
      ],
    );
  }

  Widget _buildActiveStatus(
    bool active,
    ColorScheme colorScheme, {
    bool horizontal = false,
  }) {
    return Container(
      width: horizontal ? null : double.infinity,
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
        active ? 'ONLINE' : 'OFFLINE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? Colors.green : colorScheme.error,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAssignment(
    BuildContext context,
    String? assignedUid,
    ColorScheme colorScheme, {
    required double fontSize,
    required double iconSize,
    required bool isGrid,
  }) {
    if (assignedUid != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(assignedUid)
            .get(),
        builder: (context, userSnap) {
          String userName = assignedUid;
          if (userSnap.hasData && userSnap.data!.exists) {
            final userData = userSnap.data!.data()! as Map<String, dynamic>;
            final firstName = userData['firstname'] ?? '';
            final lastName = userData['lastname'] ?? '';
            final fullName = (firstName + ' ' + lastName).trim();
            userName = fullName.isNotEmpty ? fullName : assignedUid;
          }
          return Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: iconSize,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isGrid ? userName : 'Assigned to: $userName',
                  style: TextStyle(
                    fontSize: fontSize,
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
      );
    } else {
      return Row(
        children: [
          Icon(Icons.person_off_outlined, size: iconSize, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            'Unassigned',
            style: TextStyle(
              fontSize: fontSize,
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionButtons(ColorScheme colorScheme, {bool compact = false}) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.videocam_outlined,
          label: compact ? '' : 'Live Feed',
          onPressed: widget.onLiveFeed,
          colorScheme: colorScheme,
          compact: compact,
        ),
        if (!compact) const Spacer(),
        _buildActionButton(
          icon: Icons.settings_remote_rounded,
          label: compact ? '' : 'Control',
          onPressed: widget.onControl,
          isPrimary: true,
          colorScheme: colorScheme,
          compact: compact,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    required ColorScheme colorScheme,
    bool isPrimary = false,
    bool compact = false,
  }) {
    return SizedBox(
      height: compact ? 32 : 36,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: compact ? 14 : 16),
              label: label.isNotEmpty
                  ? Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 10 : 12,
                      ),
                    )
                  : const SizedBox.shrink(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shadowColor: colorScheme.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: compact ? 14 : 16),
              label: label.isNotEmpty
                  ? Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 10 : 12,
                      ),
                    )
                  : const SizedBox.shrink(),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withOpacity(0.7),
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              ),
            ),
    );
  }

  String _shortId(String id, [int max = 15]) =>
      id.length > max ? '${id.substring(0, max)}...' : id;
}
