import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bot_card.dart';
import '../widgets/bot_empty_state.dart';

class BotListPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const BotListPage({super.key, this.arguments});

  @override
  State<BotListPage> createState() => _BotListPageState();
}

class _BotListPageState extends State<BotListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentUserRole;
  String? _currentUserId;
  String? _actionType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _actionType = widget.arguments?['action'] as String?;
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _getUserRole();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getUserRole() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _currentUserRole = userDoc.data()?['role'];
        });
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
  }

  Stream<QuerySnapshot> _getBotStream() {
    if (_currentUserRole == 'admin') {
      return _firestore
          .collection('bots')
          .where('owner_admin_id', isEqualTo: _currentUserId)
          .snapshots();
    } else if (_currentUserRole == 'field_operator') {
      return _firestore
          .collection('bots')
          .where('assigned_to', isEqualTo: _currentUserId)
          .snapshots();
    } else {
      // Return empty stream for unknown roles
      return const Stream.empty();
    }
  }

  String _getPageTitle() {
    switch (_actionType) {
      case 'live-feed':
        return 'Select Bot for Live Feed';
      case 'control':
        return 'Select Bot to Control';
      case 'emergency-recall':
        return 'Select Bot for Emergency Recall';
      default:
        return 'Select Bot';
    }
  }

  String _getSubtitle() {
    if (_currentUserRole == 'admin') {
      return 'My Bots';
    } else if (_currentUserRole == 'field_operator') {
      return 'My Assigned Bots';
    }
    return 'Available Bots';
  }

  void _handleBotTap(DocumentSnapshot botDoc) {
    switch (_actionType) {
      case 'live-feed':
        Navigator.pushNamed(context, '/live-feed', arguments: botDoc);
        break;
      case 'control':
        _showComingSoon('Bot Control');
        break;
      case 'emergency-recall':
        _showEmergencyRecallDialog(botDoc);
        break;
      default:
        Navigator.pushNamed(context, '/live-feed', arguments: botDoc);
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showEmergencyRecallDialog(DocumentSnapshot botDoc) {
    final botData = botDoc.data() as Map<String, dynamic>;
    final botName = botData['name'] ?? 'Bot ${botDoc.id}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Recall'),
        content: Text('Are you sure you want to recall $botName immediately?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Emergency Recall');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Recall'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: colorScheme.background,
          foregroundColor: colorScheme.onBackground,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUserId == null || _currentUserRole == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getPageTitle()),
          backgroundColor: colorScheme.background,
          foregroundColor: colorScheme.onBackground,
        ),
        body: const BotEmptyState(
          icon: Icons.person_off_outlined,
          message: 'Authentication Required',
          subMessage: 'Please log in to access bot management',
        ),
      );
    }

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
              _getPageTitle(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              _getSubtitle(),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getBotStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return BotEmptyState(
              icon: Icons.error_outline,
              message: 'Error Loading Bots',
              subMessage: 'Please try again later',
            );
          }

          final bots = snapshot.data?.docs ?? [];

          if (bots.isEmpty) {
            return BotEmptyState(
              icon: Icons.directions_boat_outlined,
              message: 'No Bots Available',
              subMessage: _currentUserRole == 'admin'
                  ? 'You haven\'t created any bots yet'
                  : 'No bots have been assigned to you',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bots.length,
            itemBuilder: (context, index) {
              final botDoc = bots[index];
              final botData = botDoc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => _handleBotTap(botDoc),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.directions_boat_rounded,
                              color: colorScheme.onPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  botData['name'] ?? 'Bot ${botDoc.id}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${botDoc.id}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (botData['active'] ?? false)
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (botData['active'] ?? false)
                                            ? 'ACTIVE'
                                            : 'INACTIVE',
                                        style: TextStyle(
                                          color: (botData['active'] ?? false)
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        botData['status']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'UNKNOWN',
                                        style: TextStyle(
                                          color: colorScheme.secondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: colorScheme.onSurface.withOpacity(0.4),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
