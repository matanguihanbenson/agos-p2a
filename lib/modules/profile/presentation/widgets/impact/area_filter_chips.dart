import 'package:flutter/material.dart';

class AreaFilterChips extends StatelessWidget {
  final String? selectedArea;
  final Function(String?) onAreaSelected;

  const AreaFilterChips({
    super.key,
    required this.selectedArea,
    required this.onAreaSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final areas = [
      {'id': null, 'label': 'All Areas', 'icon': Icons.public},
      {'id': 'calapan_river', 'label': 'Calapan River', 'icon': Icons.waves},
      {'id': 'bucayao_river', 'label': 'Bucayao River', 'icon': Icons.waves},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: areas.map((area) {
          final isSelected = selectedArea == area['id'];

          return GestureDetector(
            onTap: () => onAreaSelected(area['id'] as String?),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show icon only when NOT selected
                  if (!isSelected) ...[
                    Icon(
                      area['icon'] as IconData,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    area['label'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  // Show checkmark only when selected
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
