import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'area_filter_chips.dart';
import 'metric_summary_card.dart';
import 'compact_chart_widget.dart';
import 'timeframe_selector.dart';

enum UserRole { admin, fieldOperator }

class ImpactDashboard extends StatefulWidget {
  final UserRole userRole;
  final String? userId;

  const ImpactDashboard({super.key, required this.userRole, this.userId});

  @override
  State<ImpactDashboard> createState() => _ImpactDashboardState();
}

class _ImpactDashboardState extends State<ImpactDashboard> {
  String? selectedArea = 'all';
  String selectedTimeframe = 'month';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header Section
          SliverToBoxAdapter(child: _buildHeader()),

          // Filters Section
          SliverToBoxAdapter(child: _buildFilters()),

          // Summary Cards Section
          SliverToBoxAdapter(child: _buildSummaryCards()),

          // Charts Section
          SliverToBoxAdapter(child: _buildChartsSection()),

          // Additional Content based on role
          if (widget.userRole == UserRole.fieldOperator)
            SliverToBoxAdapter(child: _buildAchievementsSection()),

          // Add bottom padding for better scrolling
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.userRole == UserRole.admin ? Icons.analytics : Icons.eco,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userRole == UserRole.admin
                          ? 'Environmental Impact Overview'
                          : 'Your Environmental Impact',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.userRole == UserRole.admin
                          ? 'Track progress across all operations'
                          : 'See how you\'re making a difference',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showInfoDialog(),
                icon: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                tooltip: 'About Impact Metrics',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Area Filter
          AreaFilterChips(
            selectedArea: selectedArea,
            onAreaSelected: (area) {
              setState(() {
                selectedArea = area;
              });
            },
          ),
          const SizedBox(height: 16),

          // Timeframe Selector
          TimeframeSelector(
            selectedTimeframe: selectedTimeframe,
            onTimeframeChanged: (timeframe) {
              setState(() {
                selectedTimeframe = timeframe;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Metrics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _getMetrics().length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final metric = _getMetrics()[index];
                return SizedBox(
                  width: 140,
                  child: MetricSummaryCard(
                    title: metric['title']!,
                    value: metric['value']!,
                    unit: metric['unit']!,
                    trend: metric['trend'] as double,
                    icon: metric['icon'] as IconData,
                    color: metric['color'] as Color,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trends',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Trash Collection Chart
          CompactChartWidget(
            title: 'Trash Collected (kg)',
            data: _getTrashData(),
            color: Colors.green,
            icon: Icons.delete_outline,
          ),
          const SizedBox(height: 16),

          // Water Quality Charts
          Row(
            children: [
              Expanded(
                child: CompactChartWidget(
                  title: 'pH Level',
                  data: _getPhData(),
                  color: Colors.blue,
                  icon: Icons.water_drop,
                  isSmall: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CompactChartWidget(
                  title: 'Turbidity (NTU)',
                  data: _getTurbidityData(),
                  color: Colors.orange,
                  icon: Icons.visibility,
                  isSmall: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eco Warrior',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Collected 100kg+ trash this month',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '75kg / 100kg towards next milestone',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMetrics() {
    if (widget.userRole == UserRole.admin) {
      return [
        {
          'title': 'Total Trash',
          'value': '1,250',
          'unit': 'kg',
          'trend': 15.2,
          'icon': Icons.delete_outline,
          'color': Colors.green,
        },
        {
          'title': 'Avg pH',
          'value': '7.4',
          'unit': '',
          'trend': 5.8,
          'icon': Icons.water_drop,
          'color': Colors.blue,
        },
        {
          'title': 'Avg Turbidity',
          'value': '18.5',
          'unit': 'NTU',
          'trend': -12.3,
          'icon': Icons.visibility,
          'color': Colors.orange,
        },
        {
          'title': 'Active Areas',
          'value': '6',
          'unit': '',
          'trend': 20.0,
          'icon': Icons.location_on,
          'color': Colors.purple,
        },
      ];
    } else {
      return [
        {
          'title': 'Trash Collected',
          'value': '75',
          'unit': 'kg',
          'trend': 25.0,
          'icon': Icons.delete_outline,
          'color': Colors.green,
        },
        {
          'title': 'Missions',
          'value': '12',
          'unit': '',
          'trend': 15.0,
          'icon': Icons.flag,
          'color': Colors.blue,
        },
        {
          'title': 'Water Quality',
          'value': '7.2',
          'unit': 'pH',
          'trend': 8.5,
          'icon': Icons.water_drop,
          'color': Colors.orange,
        },
      ];
    }
  }

  List<FlSpot> _getTrashData() {
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

  List<FlSpot> _getPhData() {
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

  List<FlSpot> _getTurbidityData() {
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

  Future<void> _refreshData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Refresh data logic here
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impact Metrics'),
        content: const Text(
          'These metrics show your environmental impact including trash collected, water quality improvements, and area coverage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
