import 'package:flutter/material.dart';

class ScheduleFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<Map<String, dynamic>> schedules;

  const ScheduleFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Schedules',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_getFilteredCount()} of ${schedules.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', _getStatusCount('all')),
                const SizedBox(width: 8),
                _buildFilterChip('scheduled', 'Scheduled', _getStatusCount('scheduled')),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Active', _getStatusCount('active')),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed', _getStatusCount('completed')),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Cancelled', _getStatusCount('cancelled')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = selectedFilter == value;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => onFilterChanged(value),
      selectedColor: Colors.blue.withOpacity(0.1),
      checkmarkColor: Colors.blue,
    );
  }

  int _getStatusCount(String status) {
    if (status == 'all') return schedules.length;
    return schedules.where((s) => s['status'] == status).length;
  }

  int _getFilteredCount() {
    if (selectedFilter == 'all') return schedules.length;
    return schedules.where((s) => s['status'] == selectedFilter).length;
  }
}
