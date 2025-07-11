import 'package:flutter/material.dart';

class ImpactHeader extends StatefulWidget {
  final Function(String bot, String area)? onFilterChanged;

  const ImpactHeader({super.key, this.onFilterChanged});

  @override
  State<ImpactHeader> createState() => _ImpactHeaderState();
}

class _ImpactHeaderState extends State<ImpactHeader> {
  String selectedBot = 'All Bots';
  String selectedArea = 'All Areas';

  final List<String> bots = ['All Bots', 'Bot A1', 'Bot B2', 'Bot C3'];
  final List<String> areas = [
    'All Areas',
    'Beach Zone',
    'Harbor Area',
    'Coastal Strip',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.background, theme.colorScheme.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environmental',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    Text(
                      'Impact',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Select Bot',
                  selectedBot,
                  bots,
                  Icons.smart_toy_outlined,
                  (value) {
                    setState(() => selectedBot = value!);
                    widget.onFilterChanged?.call(selectedBot, selectedArea);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Select Area',
                  selectedArea,
                  areas,
                  Icons.location_on_outlined,
                  (value) {
                    setState(() => selectedArea = value!);
                    widget.onFilterChanged?.call(selectedBot, selectedArea);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, size: 18),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
