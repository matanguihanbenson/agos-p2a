import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/bot_details_controller.dart';
import '../widgets/bot_details/stat_card.dart';
import '../widgets/bot_details/admin_actions.dart';
import '../widgets/bot_details/user_actions.dart';
import '../widgets/bot_details/location_tab.dart';
import '../widgets/bot_details/technical_tab.dart';
import '../widgets/bot_details/assignment_card.dart';

class BotDetailsPage extends StatefulWidget {
  final DocumentSnapshot doc;
  final int index;

  const BotDetailsPage({Key? key, required this.doc, required this.index})
    : super(key: key);

  @override
  State<BotDetailsPage> createState() => _BotDetailsPageState();
}

class _BotDetailsPageState extends State<BotDetailsPage>
    with SingleTickerProviderStateMixin {
  late final BotDetailsController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = BotDetailsController(botId: widget.doc.id)
      ..addListener(() => setState(() {}));
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final realtime = _controller.realtimeData;
    final isAdmin = _controller.isAdmin;
    final firestoreData = widget.doc.data()! as Map<String, dynamic>;

    final name = (firestoreData['name'] as String?)?.trim();
    final displayName = (name != null && name.isNotEmpty)
        ? name
        : 'Bot #${widget.index + 1}';
    final cs = Theme.of(context).colorScheme;

    final active = realtime?['active'] ?? firestoreData['active'] ?? false;
    final status = (realtime?['status'] ?? firestoreData['status'])
        .toString()
        .toUpperCase();
    final battery = (realtime?['battery'] ?? firestoreData['battery'])
        ?.toString();
    final assignedUid = firestoreData['assigned_to'] as String?;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _buildAppBar(displayName, cs, active),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Assignment card
            AssignmentCard(
              assignedUid: assignedUid,
              cs: cs,
            ),

            // Status overview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.power_settings_new,
                          label: 'Power',
                          value: active ? 'ON' : 'OFF',
                          color: active ? Colors.green : Colors.red,
                          isLive: realtime != null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.battery_charging_full,
                          label: 'Battery',
                          value: battery != null
                              ? (battery.endsWith('%') ? battery : '$battery%')
                              : 'N/A',
                          color: _batteryColor(battery),
                          isLive: realtime != null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.settings_outlined,
                          label: 'Status',
                          value: status,
                          color: _statusColor(status),
                          isLive: realtime != null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurface.withOpacity(0.6),
                    indicatorColor: cs.primary,
                    tabs: const [
                      Tab(text: 'Location'),
                      Tab(text: 'Technical'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        LocationTab(realtime: realtime, data: firestoreData),
                        TechnicalTab(realtime: realtime, data: firestoreData),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 8,
        ),
        child: isAdmin
            ? AdminActions(
                docRef: widget.doc.reference,
                assignedTo: assignedUid,
              )
            : UserActions(),
      ),
    );
  }

  AppBar _buildAppBar(String displayName, ColorScheme cs, bool active) {
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      leadingWidth: 40,
      leading: BackButton(color: cs.onSurface),
      titleSpacing: 8,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_boat_rounded,
              color: cs.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'ID: ${_shortId(widget.doc.id, 12)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                active ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatorCard(String? assignedUid, ColorScheme cs) {
    return const SizedBox.shrink();
  }

  Color _batteryColor(String? b) {
    final lvl = int.tryParse(b ?? '') ?? 0;
    if (lvl > 50) return Colors.green;
    if (lvl > 20) return Colors.orange;
    return Colors.red;
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
      case 'deployed':
        return Colors.green;
      case 'inactive':
      case 'recalled':
        return Colors.orange;
      case 'error':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _shortId(String id, [int max = 15]) =>
      id.length > max ? '${id.substring(0, max)}...' : id;
}
