import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class RecentActivityWidget extends StatelessWidget {
  final String userRole;
  const RecentActivityWidget({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
}
