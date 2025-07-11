import 'package:flutter/material.dart';
import 'metric_card.dart';

class WaterQualityMetrics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Water Quality Improvements',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'pH Level',
                value: '7.2',
                subtitle: '+0.8 improvement',
                icon: Icons.water_drop,
                color: Colors.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Turbidity',
                value: '2.1 NTU',
                subtitle: '-1.5 reduction',
                icon: Icons.visibility,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
