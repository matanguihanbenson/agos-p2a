import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class StatsOverviewWidget extends StatelessWidget {
  final String userRole;
  final String userId;
  const StatsOverviewWidget({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // You can later replace these hardcoded values with real database calls!
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
          return _StatCard(stat: stat, theme: theme);
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> stat;
  final ThemeData theme;
  const _StatCard({required this.stat, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (stat['isPositive'] as bool ? Colors.green : Colors.red)
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
  }
}
