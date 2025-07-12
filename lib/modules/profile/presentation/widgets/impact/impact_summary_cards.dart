import 'package:flutter/material.dart';

class ImpactSummaryCards extends StatelessWidget {
  final String userRole;
  final String? selectedArea;
  final String? timePeriod; // Add time period parameter

  const ImpactSummaryCards({
    super.key,
    required this.userRole,
    this.selectedArea,
    this.timePeriod = 'month',
  });

  @override
  Widget build(BuildContext context) {
    final metrics = _getMetricsForRole(userRole);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        childAspectRatio: 1.1, // Reduced from 1.3 to give more height
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _MetricCard(
          title: metric['title']!,
          value: metric['value']!,
          unit: metric['unit']!,
          icon: metric['icon'] as IconData,
          color: metric['color'] as Color,
          trend: metric['trend'] as double,
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMetricsForRole(String role) {
    // Get time period specific multiplier for realistic data
    final multiplier = _getTimePeriodMultiplier(timePeriod ?? 'month');

    if (role == 'admin') {
      return [
        {
          'title': 'Total Trash',
          'value':
              '${(1250 * multiplier).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          'unit': 'items', // Changed from 'kg'
          'icon': Icons.delete_outline,
          'color': Colors.green,
          'trend': 15.2,
        },
        {
          'title': 'Avg pH',
          'value': '7.4',
          'unit': '',
          'icon': Icons.water_drop,
          'color': Colors.blue,
          'trend': 5.8,
        },
        {
          'title': 'Turbidity',
          'value': '${(18.5 / multiplier).toStringAsFixed(1)}',
          'unit': 'NTU',
          'icon': Icons.visibility,
          'color': Colors.orange,
          'trend': -12.3,
        },
        {
          'title': 'Active Areas',
          'value': '6',
          'unit': '',
          'icon': Icons.location_on,
          'color': Colors.purple,
          'trend': 20.0,
        },
      ];
    } else {
      return [
        {
          'title': 'Trash Collected',
          'value': '${(75 * multiplier).toInt()}',
          'unit': 'items', // Changed from 'kg'
          'icon': Icons.delete_outline,
          'color': Colors.green,
          'trend': 25.0,
        },
        {
          'title': 'Operations',
          'value': '${(12 * multiplier).toInt()}',
          'unit': '',
          'icon': Icons.directions_boat,
          'color': Colors.blue,
          'trend': 15.0,
        },
        {
          'title': 'Water Quality',
          'value': '7.2',
          'unit': 'pH',
          'icon': Icons.water_drop,
          'color': Colors.orange,
          'trend': 8.5,
        },
        {
          'title': 'Areas Covered',
          'value': '${(4 * (multiplier * 0.5)).toInt()}',
          'unit': '',
          'icon': Icons.map_outlined,
          'color': Colors.teal,
          'trend': 12.5,
        },
      ];
    }
  }

  double _getTimePeriodMultiplier(String period) {
    switch (period) {
      case 'day':
        return 0.033; // ~1/30 of month
      case 'week':
        return 0.25; // ~1/4 of month
      case 'month':
        return 1.0;
      case 'year':
        return 12.0; // 12 months
      default:
        return 1.0;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double trend;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = trend >= 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
          children: [
            // Header with icon and trend
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced from 8 to 6
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ), // Reduced from 20 to 18
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18), // Add consistent spacing
            // Value
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 11, // Slightly smaller
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Title
            Flexible(
              // Wrap title in Flexible to prevent overflow
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 12, // Slightly smaller
                ),
                maxLines: 2, // Allow 2 lines for longer titles
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
