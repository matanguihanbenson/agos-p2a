import 'package:flutter/material.dart';

class BotSearchAndFilter extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String statusFilter;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final String userRole;

  const BotSearchAndFilter({
    super.key,
    required this.searchCtrl,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: userRole == 'admin'
                  ? 'Search all bots by name or ID...'
                  : 'Search your bots by name or ID...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: TextStyle(color: colorScheme.onBackground),
            onChanged: (_) => onSearchChanged(),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'deployed', 'recalled', 'active', 'inactive']
                  .map((filter) {
                    final isSelected = statusFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        label: Text(
                          filter == 'All' ? 'All' : filter.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => onFilterChanged(filter),
                        backgroundColor: colorScheme.surface,
                        selectedColor: colorScheme.primary,
                        checkmarkColor: colorScheme.onPrimary,
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
