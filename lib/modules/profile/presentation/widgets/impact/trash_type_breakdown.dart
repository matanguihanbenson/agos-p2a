import 'package:flutter/material.dart';
import 'trash_type_item.dart';

class TrashTypeBreakdown extends StatelessWidget {
  const TrashTypeBreakdown({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waste Removed',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  Text(
                    'by Type',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bar_chart_outlined, size: 16),
                label: const Text('Analysis'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: const [
                TrashTypeItem(
                  type: 'Plastic',
                  percentage: 45,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(height: 16),
                TrashTypeItem(
                  type: 'Glass',
                  percentage: 20,
                  color: Color(0xFF10B981),
                ),
                SizedBox(height: 16),
                TrashTypeItem(
                  type: 'Metal',
                  percentage: 25,
                  color: Color(0xFF8B5CF6),
                ),
                SizedBox(height: 16),
                TrashTypeItem(
                  type: 'Organic',
                  percentage: 10,
                  color: Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
