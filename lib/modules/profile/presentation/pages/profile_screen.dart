import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/user_providers.dart';
import '../../../../core/models/user_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_cards.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_item.dart';
import '../widgets/profile_dialogs.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/impact/impact_summary_cards.dart';
import '../widgets/impact/area_filter_chips.dart';
import '../widgets/impact/compact_metrics_chart.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (userProfile) {
        if (userProfile == null) {
          return const Scaffold(
            body: Center(child: Text('User profile not found')),
          );
        }
        return _ProfileBody(userProfile: userProfile);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Unable to load profile'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.refresh(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile userProfile;
  const _ProfileBody({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.eco), text: 'Impact'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
              Tab(icon: Icon(Icons.help), text: 'Support'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfileTab(userProfile: userProfile),
            _ImpactTab(),
            _SettingsTab(userProfile: userProfile),
            _SupportTab(),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final UserProfile userProfile;
  const _ProfileTab({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeader(userProfile: userProfile),
          const SizedBox(height: 24),

          const SizedBox(height: 24),

          ProfileInfoCards(userProfile: userProfile),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final UserProfile userProfile;
  const _SettingsTab({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SettingsSection(
            title: 'Preferences',
            items: [
              SettingsItem(
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                icon: Icons.notifications_outlined,
                onTap: () {
                  // TODO: Add notification settings
                },
              ),
              SettingsItem(
                title: 'Privacy',
                subtitle: 'Control your privacy settings',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  // TODO: Add privacy settings
                },
              ),
              SettingsItem(
                title: 'Change Password',
                subtitle: 'Update your account password',
                icon: Icons.lock_outline,
                onTap: () => ProfileDialogs.showChangePasswordDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SettingsSection(
            title: 'Data & Privacy',
            items: [
              SettingsItem(
                title: 'Export Data',
                subtitle: 'Download your account data',
                icon: Icons.download,
                onTap: () => ProfileDialogs.exportData(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SupportTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SettingsSection(
            title: 'Help & Support',
            items: [
              SettingsItem(
                title: 'Help Center',
                subtitle: 'Get help and find answers',
                icon: Icons.help_outline,
                onTap: () => ProfileDialogs.showHelpCenter(context),
              ),
              SettingsItem(
                title: 'Contact Support',
                subtitle: 'Reach out to our support team',
                icon: Icons.support_agent,
                onTap: () => ProfileDialogs.contactSupport(context),
              ),
              SettingsItem(
                title: 'Report a Bug',
                subtitle: 'Help us improve the app',
                icon: Icons.bug_report,
                onTap: () => ProfileDialogs.reportBug(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ImpactTab extends StatefulWidget {
  @override
  State<_ImpactTab> createState() => _ImpactTabState();
}

class _ImpactTabState extends State<_ImpactTab> {
  String?
  _selectedArea; // This will default to null which represents "All Areas"
  String _selectedTimePeriod = 'month';
  String _selectedTrendPeriod = 'week'; // Separate filter for trends

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Impact Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Environmental Impact',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your contribution to cleaner waters',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Filters Section (moved up)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 20,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filters',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AreaFilterChips(
                    selectedArea: _selectedArea,
                    onAreaSelected: (area) {
                      setState(() => _selectedArea = area);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Time Period Selector
                  _buildTimePeriodSelector(theme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Summary Cards Section (with clearer context)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.dashboard_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Overview - ${_getTimePeriodLabel(_selectedTimePeriod)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Key metrics for ${_getAreaLabel(_selectedArea)} ${_selectedTimePeriod == 'day' ? 'today' : 'this $_selectedTimePeriod'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final userRoleAsync = ref.watch(userRoleProvider);
                      return userRoleAsync.when(
                        data: (userRole) => ImpactSummaryCards(
                          userRole: userRole,
                          selectedArea: _selectedArea,
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => Container(
                          padding: const EdgeInsets.all(20),
                          child: const Text('Unable to load impact data'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Charts Section (improved layout)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.show_chart,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trends & Analytics',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Monitor environmental metrics over time',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Trend Period Filter
                  _buildTrendPeriodSelector(theme),

                  const SizedBox(height: 16),

                  // Vertical Chart Cards (full width)
                  Column(
                    children: [
                      _buildDetailedMetricCard(0, theme),
                      const SizedBox(height: 16),
                      _buildDetailedMetricCard(1, theme),
                      const SizedBox(height: 16),
                      _buildDetailedMetricCard(2, theme),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // View More Actions - REMOVED
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: OutlinedButton.icon(
                  //         onPressed: () => _showCustomDatePicker(context),
                  //         icon: const Icon(Icons.date_range, size: 18),
                  //         label: const Text('Custom Range'),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Expanded(
                  //       child: ElevatedButton.icon(
                  //         onPressed: () {
                  //           // Navigate to detailed analytics
                  //         },
                  //         icon: const Icon(Icons.analytics, size: 18),
                  //         label: const Text('Detailed View'),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),

          // Detailed Impact Panel
          // ...existing code...
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector(ThemeData theme) {
    final periods = [
      {'id': 'day', 'label': 'Today'},
      {'id': 'week', 'label': 'This Week'},
      {'id': 'month', 'label': 'This Month'},
      {'id': 'year', 'label': 'This Year'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedTimePeriod == period['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimePeriod = period['id']!;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                period['label']!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendPeriodSelector(ThemeData theme) {
    final periods = [
      {'id': 'day', 'label': 'Daily', 'description': 'Last 7 days'},
      {'id': 'week', 'label': 'Weekly', 'description': 'Last 8 weeks'},
      {'id': 'month', 'label': 'Monthly', 'description': 'Last 12 months'},
      {'id': 'year', 'label': 'Yearly', 'description': 'Last 5 years'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Trend Period',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: periods.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final period = periods[index];
              final isSelected = _selectedTrendPeriod == period['id'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTrendPeriod = period['id']!;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        period['label']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        period['description']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withOpacity(0.8)
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.7,
                                ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetricCard(int index, ThemeData theme) {
    final chartData = _getChartData(index);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with detailed info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (chartData['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    chartData['icon'] as IconData,
                    color: chartData['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chartData['title'] as String,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_getTrendPeriodDescription(_selectedTrendPeriod)} • ${_getAreaLabel(_selectedArea)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chartData['context'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Only show the trend indicator badge, remove current value
                _buildTrendIndicator(chartData['change'] as String, theme),
              ],
            ),

            const SizedBox(height: 20),

            // Chart with more height for detail
            SizedBox(
              height: 180,
              child: CompactMetricsChart(
                title: chartData['title'] as String,
                subtitle: chartData['subtitle'] as String,
                data: chartData['data'] as List<FlSpot>,
                color: chartData['color'] as Color,
                unit: chartData['unit'] as String,
                showImprovement: false,
                timeLabels: chartData['timeLabels'] as List<String>?,
              ),
            ),

            const SizedBox(height: 16),

            // Additional metrics row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Average',
                      _getAverageValue(index),
                      Icons.analytics_outlined,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Peak',
                      _getPeakValue(index),
                      Icons.trending_up,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Target',
                      _getTargetValue(index),
                      Icons.flag_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getAverageValue(int index) {
    switch (index) {
      case 0:
        return '22 items'; // Changed from '22.4kg'
      case 1:
        return '7.2';
      case 2:
        return '16.8 NTU';
      default:
        return '0';
    }
  }

  String _getPeakValue(int index) {
    switch (index) {
      case 0:
        return '35 items'; // Changed from '35.2kg'
      case 1:
        return '8.1';
      case 2:
        return '28.5 NTU';
      default:
        return '0';
    }
  }

  String _getTargetValue(int index) {
    switch (index) {
      case 0:
        return '30 items'; // Changed from '30kg'
      case 1:
        return '7.5';
      case 2:
        return '<15 NTU';
      default:
        return '0';
    }
  }

  Widget _buildTrendIndicator(
    String change,
    ThemeData theme, {
    bool isSmall = false,
  }) {
    final isPositive = !change.startsWith('-');
    final changeValue = change.replaceAll('+', '').replaceAll('-', '');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 4 : 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
            size: isSmall ? 10 : 12,
          ),
          const SizedBox(width: 2),
          Text(
            '$changeValue%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }

  String _getTrendPeriodDescription(String period) {
    switch (period) {
      case 'day':
        return 'Last 7 days';
      case 'week':
        return 'Last 8 weeks';
      case 'month':
        return 'Last 12 months';
      case 'year':
        return 'Last 5 years';
      default:
        return 'Last 7 days';
    }
  }

  String _getTimePeriodLabel(String period) {
    switch (period) {
      case 'day':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      default:
        return 'This Month';
    }
  }

  String _getAreaLabel(String? area) {
    if (area == null) return 'all areas'; // Handle null case for "All Areas"
    return area
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  Map<String, dynamic> _getChartData(int index) {
    switch (index) {
      case 0:
        return {
          'title': 'Trash Collected',
          'subtitle': 'Daily collection',
          // Remove 'currentValue' as it's no longer needed
          'change': '+12.5',
          'context': 'vs. previous week average',
          'data': _getTrashData(),
          'color': Colors.green,
          'unit': 'items',
          'icon': Icons.delete_outline,
          'timeLabels': _getTimeLabels(_selectedTrendPeriod),
        };
      case 1:
        return {
          'title': 'pH Level',
          'subtitle': 'Water quality',
          // Remove 'currentValue' as it's no longer needed
          'change': '+5.4',
          'context': 'within optimal range',
          'data': _getPhData(),
          'color': Colors.blue,
          'unit': '',
          'icon': Icons.water_drop,
          'timeLabels': _getTimeLabels(_selectedTrendPeriod),
        };
      case 2:
        return {
          'title': 'Turbidity',
          'subtitle': 'Water clarity',
          // Remove 'currentValue' as it's no longer needed
          'change': '-15.2',
          'context': 'improving clarity',
          'data': _getTurbidityData(),
          'color': Colors.cyan,
          'unit': 'NTU',
          'icon': Icons.visibility,
          'timeLabels': _getTimeLabels(_selectedTrendPeriod),
        };
      default:
        return {};
    }
  }

  List<String> _getTimeLabels(String period) {
    switch (period) {
      case 'day':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'week':
        return ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'];
      case 'month':
        return [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
      case 'year':
        return ['Y1', 'Y2', 'Y3', 'Y4', 'Y5'];
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
  }

  List<FlSpot> _getTrashData() {
    // Adjust data points based on selected trend period
    switch (_selectedTrendPeriod) {
      case 'day':
        return [
          const FlSpot(0, 12), // Mon
          const FlSpot(1, 18), // Tue
          const FlSpot(2, 15), // Wed
          const FlSpot(3, 22), // Thu
          const FlSpot(4, 19), // Fri
          const FlSpot(5, 25), // Sat
          const FlSpot(6, 28), // Sun
        ];
      case 'week':
        return [
          const FlSpot(0, 85), // W1
          const FlSpot(1, 95), // W2
          const FlSpot(2, 78), // W3
          const FlSpot(3, 112), // W4
          const FlSpot(4, 98), // W5
          const FlSpot(5, 125), // W6
          const FlSpot(6, 135), // W7
          const FlSpot(7, 142), // W8
        ];
      case 'month':
        return [
          const FlSpot(0, 320), // Jan
          const FlSpot(1, 280), // Feb
          const FlSpot(2, 350), // Mar
          const FlSpot(3, 390), // Apr
          const FlSpot(4, 420), // May
          const FlSpot(5, 380), // Jun
          const FlSpot(6, 450), // Jul
          const FlSpot(7, 480), // Aug
          const FlSpot(8, 460), // Sep
          const FlSpot(9, 520), // Oct
          const FlSpot(10, 490), // Nov
          const FlSpot(11, 550), // Dec
        ];
      case 'year':
        return [
          const FlSpot(0, 4200), // Y1
          const FlSpot(1, 4800), // Y2
          const FlSpot(2, 5200), // Y3
          const FlSpot(3, 5800), // Y4
          const FlSpot(4, 6200), // Y5
        ];
      default:
        return [
          const FlSpot(0, 12),
          const FlSpot(1, 18),
          const FlSpot(2, 15),
          const FlSpot(3, 22),
          const FlSpot(4, 19),
          const FlSpot(5, 25),
          const FlSpot(6, 28),
        ];
    }
  }

  List<FlSpot> _getPhData() {
    switch (_selectedTrendPeriod) {
      case 'day':
        return [
          const FlSpot(0, 6.8), // Mon
          const FlSpot(1, 7.0), // Tue
          const FlSpot(2, 7.2), // Wed
          const FlSpot(3, 7.1), // Thu
          const FlSpot(4, 7.4), // Fri
          const FlSpot(5, 7.6), // Sat
          const FlSpot(6, 7.8), // Sun
        ];
      case 'week':
        return [
          const FlSpot(0, 6.5), // W1
          const FlSpot(1, 6.8), // W2
          const FlSpot(2, 7.0), // W3
          const FlSpot(3, 7.2), // W4
          const FlSpot(4, 7.1), // W5
          const FlSpot(5, 7.4), // W6
          const FlSpot(6, 7.6), // W7
          const FlSpot(7, 7.8), // W8
        ];
      case 'month':
        return [
          const FlSpot(0, 6.2), // Jan
          const FlSpot(1, 6.4), // Feb
          const FlSpot(2, 6.6), // Mar
          const FlSpot(3, 6.8), // Apr
          const FlSpot(4, 7.0), // May
          const FlSpot(5, 7.1), // Jun
          const FlSpot(6, 7.3), // Jul
          const FlSpot(7, 7.4), // Aug
          const FlSpot(8, 7.5), // Sep
          const FlSpot(9, 7.6), // Oct
          const FlSpot(10, 7.7), // Nov
          const FlSpot(11, 7.8), // Dec
        ];
      case 'year':
        return [
          const FlSpot(0, 6.0), // Y1
          const FlSpot(1, 6.5), // Y2
          const FlSpot(2, 7.0), // Y3
          const FlSpot(3, 7.4), // Y4
          const FlSpot(4, 7.8), // Y5
        ];
      default:
        return [
          const FlSpot(0, 6.8),
          const FlSpot(1, 7.0),
          const FlSpot(2, 7.2),
          const FlSpot(3, 7.1),
          const FlSpot(4, 7.4),
          const FlSpot(5, 7.6),
          const FlSpot(6, 7.8),
        ];
    }
  }

  List<FlSpot> _getTurbidityData() {
    switch (_selectedTrendPeriod) {
      case 'day':
        return [
          const FlSpot(0, 25), // Mon
          const FlSpot(1, 23), // Tue
          const FlSpot(2, 20), // Wed
          const FlSpot(3, 18), // Thu
          const FlSpot(4, 16), // Fri
          const FlSpot(5, 14), // Sat
          const FlSpot(6, 12), // Sun
        ];
      case 'week':
        return [
          const FlSpot(0, 35), // W1
          const FlSpot(1, 32), // W2
          const FlSpot(2, 28), // W3
          const FlSpot(3, 25), // W4
          const FlSpot(4, 22), // W5
          const FlSpot(5, 18), // W6
          const FlSpot(6, 15), // W7
          const FlSpot(7, 12), // W8
        ];
      case 'month':
        return [
          const FlSpot(0, 45), // Jan
          const FlSpot(1, 42), // Feb
          const FlSpot(2, 38), // Mar
          const FlSpot(3, 35), // Apr
          const FlSpot(4, 32), // May
          const FlSpot(5, 28), // Jun
          const FlSpot(6, 25), // Jul
          const FlSpot(7, 22), // Aug
          const FlSpot(8, 20), // Sep
          const FlSpot(9, 18), // Oct
          const FlSpot(10, 15), // Nov
          const FlSpot(11, 12), // Dec
        ];
      case 'year':
        return [
          const FlSpot(0, 50), // Y1
          const FlSpot(1, 40), // Y2
          const FlSpot(2, 30), // Y3
          const FlSpot(3, 20), // Y4
          const FlSpot(4, 12), // Y5
        ];
      default:
        return [
          const FlSpot(0, 25),
          const FlSpot(1, 23),
          const FlSpot(2, 20),
          const FlSpot(3, 18),
          const FlSpot(4, 16),
          const FlSpot(5, 14),
          const FlSpot(6, 12),
        ];
    }
  }
}
