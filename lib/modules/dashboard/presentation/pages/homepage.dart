import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/user_providers.dart';
import '../../../notifications/presentation/pages/notification_screen.dart';

// Import all widgets
import '../../widgets/system_status_widget.dart';
import '../../widgets/stats_overview_widget.dart';
import '../../widgets/weather_card_widget.dart';
import '../../widgets/quick_actions_widget.dart';
import '../../widgets/environmental_data_card.dart';
import '../../widgets/recent_activity_widget.dart';

// Add provider for user's first name
final userFirstNameProvider = FutureProvider<String>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 'Guest';

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.cache)); // Try cache first

    if (doc.exists && doc.data() != null) {
      return doc.data()!['firstname'] ?? 'Guest';
    }

    // Fallback to server if cache miss
    final serverDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (serverDoc.exists && serverDoc.data() != null) {
      return serverDoc.data()!['firstname'] ?? 'Guest';
    }
    return 'Guest';
  } catch (e) {
    return 'Guest';
  }
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final userRoleAsync = ref.watch(userRoleProvider);
    final userFirstNameAsync = ref.watch(userFirstNameProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.onBackground,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.colorScheme.background, theme.colorScheme.surface],
            ),
          ),
        ),
        title: Text(
          'Dashboard',
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.logout_outlined,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : userRoleAsync.when(
              data: (userRole) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                userFirstNameAsync.when(
                                  data: (firstName) => Text(
                                    firstName,
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.onBackground,
                                        ),
                                  ),
                                  loading: () => Container(
                                    height: 36,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onBackground
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    'Guest',
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.onBackground,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userRole == 'admin'
                                      ? 'System Administrator'
                                      : 'Field Operator',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SystemStatusWidget(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      StatsOverviewWidget(userRole: userRole, userId: user.uid),
                      const SizedBox(height: 24),
                      const WeatherCardWidget(),
                      const SizedBox(height: 24),
                      // Quick Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bot Operations',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onBackground,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.settings_outlined, size: 16),
                            label: const Text('Configure'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      QuickActionsWidget(userRole: userRole),
                      const SizedBox(height: 24),
                      // Environmental Data & Recent Activity
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 800) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Environmental Monitoring',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                EnvironmentalDataCard(userRole: userRole),
                                const SizedBox(height: 24),
                                Text(
                                  'Recent Activity',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                RecentActivityWidget(userRole: userRole),
                              ],
                            );
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Environmental Monitoring',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: theme
                                                  .colorScheme
                                                  .onBackground,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      EnvironmentalDataCard(userRole: userRole),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recent Activity',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: theme
                                                  .colorScheme
                                                  .onBackground,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      RecentActivityWidget(userRole: userRole),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
              loading: () => Scaffold(
                backgroundColor: theme.colorScheme.surface,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  backgroundColor: theme.colorScheme.background,
                  title: Text(
                    'Dashboard',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading dashboard...'),
                    ],
                  ),
                ),
              ),
              error: (error, stack) {
                return const Center(child: Text('Error loading dashboard.'));
              },
            ),
    );
  }
}
