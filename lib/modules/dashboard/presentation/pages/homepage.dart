import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/user_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final userRoleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
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
                      // Handle notifications
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
                      // Welcome section with system status
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
                                Text(
                                  user.email?.split('@')[0] ?? 'Guest',
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onBackground,
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
                          _buildSystemStatus(theme),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Statistics Overview
                      _buildStatsOverview(theme, userRole, user.uid),
                      const SizedBox(height: 24),

                      // Weather Card
                      _buildWeatherCard(theme),
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
                            icon: Icon(Icons.settings_outlined, size: 16),
                            label: Text('Configure'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(theme, userRole),
                      const SizedBox(height: 24),

                      // Environmental Data & Recent Activity in Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Use column layout for smaller screens
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
                                _buildEnvironmentalDataCard(theme, userRole),
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
                                _buildRecentActivity(theme, userRole),
                              ],
                            );
                          } else {
                            // Use row layout for larger screens
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
                                      _buildEnvironmentalDataCard(
                                        theme,
                                        userRole,
                                      ),
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
                                      _buildRecentActivity(theme, userRole),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                // Fallback to field_operator if there's an error
                const userRole = 'field_operator';
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section with system status
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
                                Text(
                                  user.email?.split('@')[0] ?? 'Guest',
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onBackground,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Field Operator',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildSystemStatus(theme),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildStatsOverview(theme, userRole, user.uid),
                      const SizedBox(height: 24),
                      _buildWeatherCard(theme),
                      const SizedBox(height: 24),
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
                            icon: Icon(Icons.settings_outlined, size: 16),
                            label: Text('Configure'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(theme, userRole),
                      const SizedBox(height: 24),
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
                                _buildEnvironmentalDataCard(theme, userRole),
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
                                _buildRecentActivity(theme, userRole),
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
                                      _buildEnvironmentalDataCard(
                                        theme,
                                        userRole,
                                      ),
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
                                      _buildRecentActivity(theme, userRole),
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
            ),
    );
  }

  Widget _buildSystemStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Fleet Online',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(ThemeData theme, String userRole, String userId) {
    // Different stats based on user role
    final stats = userRole == 'admin'
        ? [
            {
              'title': 'Active Bots',
              'value': '8',
              'unit': 'of 12',
              'change': '+2',
              'isPositive': true,
              'icon': Icons.directions_boat_rounded,
              'color': Colors.green,
            },
            {
              'title': 'Water Quality Index',
              'value': '7.2',
              'unit': 'pH avg',
              'change': '+0.3',
              'isPositive': true,
              'icon': Icons.water_drop_outlined,
              'color': Colors.blue,
            },
            {
              'title': 'Pollutants Detected',
              'value': '23',
              'unit': 'alerts',
              'change': '-5',
              'isPositive': true,
              'icon': Icons.warning_amber_rounded,
              'color': Colors.orange,
            },
          ]
        : [
            {
              'title': 'My Active Bots',
              'value': '3',
              'unit': 'assigned',
              'change': '+1',
              'isPositive': true,
              'icon': Icons.directions_boat_rounded,
              'color': Colors.green,
            },
            {
              'title': 'Patrol Coverage',
              'value': '85',
              'unit': '% area',
              'change': '+12%',
              'isPositive': true,
              'icon': Icons.map_outlined,
              'color': AppTheme.primaryColor,
            },
            {
              'title': 'Data Collected',
              'value': '156',
              'unit': 'samples',
              'change': '+24',
              'isPositive': true,
              'icon': Icons.science_outlined,
              'color': Colors.purple,
            },
          ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        size: 16,
                        color: stat['color'] as Color,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (stat['isPositive'] as bool
                                    ? Colors.green
                                    : Colors.red)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        stat['change'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: stat['isPositive'] as bool
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: stat['value'] as String,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      TextSpan(
                        text: ' ${stat['unit']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMMd().format(DateTime.now()),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Manila Bay, PH',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '28°C',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Optimal for Operations',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.waves_rounded, color: Colors.white, size: 16),
                    const SizedBox(height: 4),
                    Text(
                      'Calm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, String userRole) {
    final actions = userRole == 'admin'
        ? [
            {
              'icon': Icons.videocam_rounded,
              'label': 'Fleet View',
              'color': AppTheme.secondaryColor,
              'subtitle': 'All cameras',
            },
            {
              'icon': Icons.rocket_launch_rounded,
              'label': 'Deploy All',
              'color': Colors.green,
              'subtitle': 'Mass deploy',
            },
            {
              'icon': Icons.undo_rounded,
              'label': 'Recall All',
              'color': Colors.orange,
              'subtitle': 'Emergency',
            },
            {
              'icon': Icons.admin_panel_settings_rounded,
              'label': 'Admin Panel',
              'color': Colors.purple,
              'subtitle': 'Manage fleet',
            },
          ]
        : [
            {
              'icon': Icons.videocam_rounded,
              'label': 'Live Feed',
              'color': AppTheme.secondaryColor,
              'subtitle': 'My bots',
            },
            {
              'icon': Icons.rocket_launch_rounded,
              'label': 'Deploy',
              'color': Colors.green,
              'subtitle': 'Start patrol',
            },
            {
              'icon': Icons.undo_rounded,
              'label': 'Recall',
              'color': Colors.orange,
              'subtitle': 'Return home',
            },
            {
              'icon': Icons.map_rounded,
              'label': 'Track',
              'color': Colors.blue,
              'subtitle': 'Bot locations',
            },
          ];

    return Row(
      children: actions.map((action) {
        final index = actions.indexOf(action);
        return Expanded(
          child: Container(
            height: 100,
            margin: EdgeInsets.only(
              right: index == actions.length - 1 ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Handle action tap based on action type
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          size: 20,
                          color: action['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['label'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        action['subtitle'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnvironmentalDataCard(ThemeData theme, String userRole) {
    // TODO: Replace with database values - structured for easy database integration
    final riverLocations = [
      {
        'id': 'calapan_river',
        'river': 'Calapan River',
        'location': 'Calapan City Public Market area',
        'ph': 6.8,
        'trashCount': 127,
        'waterQuality': 'Poor',
        'trashLevel': 'High',
        'temperature': 29.5,
        'turbidity': 85.2,
        'dissolvedOxygen': 4.2,
        'conductivity': 245.8,
        'lastUpdate': DateTime.now().subtract(const Duration(minutes: 5)),
        'status': 'active',
        'alertLevel': 'high',
        'color': Colors.red,
        'percentage': 35, // Overall water quality score
      },
      {
        'id': 'bucayao_river',
        'river': 'Bucayao River',
        'location': 'Barangay Bucayao, Calapan City',
        'ph': 7.2,
        'trashCount': 43,
        'waterQuality': 'Fair',
        'trashLevel': 'Moderate',
        'temperature': 28.1,
        'turbidity': 42.6,
        'dissolvedOxygen': 6.8,
        'conductivity': 198.3,
        'lastUpdate': DateTime.now().subtract(const Duration(minutes: 8)),
        'status': 'active',
        'alertLevel': 'medium',
        'color': Colors.orange,
        'percentage': 65, // Overall water quality score
      },
      {
        'id': 'panggalaan_river',
        'river': 'Panggalaan River',
        'location': 'Barangay Panggalaan, Calapan City',
        'ph': 7.6,
        'trashCount': 18,
        'waterQuality': 'Good',
        'trashLevel': 'Low',
        'temperature': 27.8,
        'turbidity': 18.4,
        'dissolvedOxygen': 8.1,
        'conductivity': 156.7,
        'lastUpdate': DateTime.now().subtract(const Duration(minutes: 3)),
        'status': 'active',
        'alertLevel': 'low',
        'color': Colors.green,
        'percentage': 85, // Overall water quality score
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calapan City Rivers',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  Text(
                    'Real-time Water Quality & Trash Monitoring',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.2),
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
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...riverLocations.map(
            (river) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    // River header
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: river['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                river['river'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                river['location'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (river['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            river['waterQuality'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              color: river['color'] as Color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Main metrics row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.water_drop_outlined,
                            label: 'pH Level',
                            value: '${river['ph']}',
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.delete_outline,
                            label: 'Trash Items',
                            value: '${river['trashCount']}',
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.thermostat_outlined,
                            label: 'Temp (°C)',
                            value: '${river['temperature']}',
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Additional metrics row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailMetric(
                            'Turbidity',
                            '${river['turbidity']} NTU',
                            theme,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailMetric(
                            'Dissolved O₂',
                            '${river['dissolvedOxygen']} mg/L',
                            theme,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailMetric(
                            'Conductivity',
                            '${river['conductivity']} μS/cm',
                            theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quality progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Water Quality Score',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${river['percentage']}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: river['color'] as Color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (river['percentage'] as int) / 100,
                          backgroundColor: theme.colorScheme.outline
                              .withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(
                            river['color'] as Color,
                          ),
                          minHeight: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Last update timestamp
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Updated ${_getTimeAgo(river['lastUpdate'] as DateTime)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to map view - will show bot locations on these rivers
                  },
                  icon: Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    'View on Map',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to detailed environmental data view
                  },
                  icon: Icon(
                    Icons.analytics_outlined,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Detailed Report',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 8,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildRecentActivity(ThemeData theme, String userRole) {
    final activities = userRole == 'admin'
        ? [
            {
              'title': 'High Trash Alert',
              'subtitle': 'Calapan River - 127 items detected',
              'time': '3 min ago',
              'icon': Icons.warning_amber_rounded,
              'color': Colors.red,
            },
            {
              'title': 'Bot Deployed',
              'subtitle': 'Panggalaan River - Bot #3',
              'time': '8 min ago',
              'icon': Icons.rocket_launch_rounded,
              'color': Colors.green,
            },
            {
              'title': 'Water Quality Alert',
              'subtitle': 'Calapan River - pH 6.8 (Low)',
              'time': '12 min ago',
              'icon': Icons.water_drop_outlined,
              'color': Colors.orange,
            },
            {
              'title': 'Trash Collection',
              'subtitle': 'Bucayao River - 15 items removed',
              'time': '18 min ago',
              'icon': Icons.cleaning_services_rounded,
              'color': Colors.green,
            },
            {
              'title': 'Temperature Spike',
              'subtitle': 'Calapan River - 29.5°C',
              'time': '25 min ago',
              'icon': Icons.thermostat_outlined,
              'color': Colors.orange,
            },
          ]
        : [
            {
              'title': 'Patrol Complete',
              'subtitle': 'Panggalaan River - Zone A',
              'time': '5 min ago',
              'icon': Icons.check_circle_outline,
              'color': Colors.green,
            },
            {
              'title': 'Trash Detected',
              'subtitle': 'Bot #2 - 8 plastic bottles',
              'time': '12 min ago',
              'icon': Icons.delete_outline,
              'color': Colors.orange,
            },
            {
              'title': 'Water Sample Taken',
              'subtitle': 'Bucayao River - pH 7.2',
              'time': '18 min ago',
              'icon': Icons.science_outlined,
              'color': Colors.blue,
            },
            {
              'title': 'Low Battery Warning',
              'subtitle': 'Bot #1 - 15% remaining',
              'time': '25 min ago',
              'icon': Icons.battery_alert_outlined,
              'color': Colors.red,
            },
            {
              'title': 'Mission Started',
              'subtitle': 'Calapan River patrol begun',
              'time': '35 min ago',
              'icon': Icons.play_arrow_rounded,
              'color': AppTheme.primaryColor,
            },
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: activities.take(5).map((activity) {
          final isLast =
              activities.indexOf(activity) == 4 ||
              activities.indexOf(activity) == activities.length - 1;
          return Container(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    size: 14,
                    color: activity['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        activity['subtitle'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activity['time'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 9,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
