import 'package:flutter/material.dart';
import 'metric_card.dart';
import 'trash_type_breakdown.dart';

class TrashCollectionMetrics extends StatelessWidget {
  const TrashCollectionMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: MetricCard(
                title: 'Total Removed',
                value: '247.5 kg',
                icon: Icons.delete_sweep,
                color: Colors.blue,
                subtitle: 'Water cleanup',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: 'Trash Collected',
                value: '1,234',
                icon: Icons.inventory_2,
                color: Colors.orange,
                subtitle: 'Items removed',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TrashTypeBreakdown(),
      ],
    );
  }
}
