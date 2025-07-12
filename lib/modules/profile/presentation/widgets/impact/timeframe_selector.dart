import 'package:flutter/material.dart';

class TimeframeSelector extends StatelessWidget {
  final String selectedTimeframe;
  final Function(String) onTimeframeChanged;

  const TimeframeSelector({
    super.key,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeframes = _getTimeframes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Time Period',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: timeframes.map((timeframe) {
              final isSelected = selectedTimeframe == timeframe['id'];
              return Flexible(
                child: GestureDetector(
                  onTap: () => onTimeframeChanged(timeframe['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      timeframe['name']!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getTimeframes() {
    return [
      {'id': 'day', 'name': 'Today'},
      {'id': 'week', 'name': 'Week'},
      {'id': 'month', 'name': 'Month'},
      {'id': 'year', 'name': 'Year'},
    ];
  }
}
