import 'package:flutter/material.dart';
import 'metric_card.dart';

class OperationsMetrics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cleanup Operations',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Total Operations',
                value: '156',
                icon: Icons.precision_manufacturing,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'This Month',
                value: '24',
                icon: Icons.calendar_month,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
