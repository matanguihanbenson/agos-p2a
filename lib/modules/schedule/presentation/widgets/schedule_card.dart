import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onRecall;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onView,
    this.onEdit,
    this.onCancel,
    this.onRecall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = schedule['status'] as String;
    final startTime = schedule['deployment_start'] as DateTime;
    final endTime = schedule['deployment_end'] as DateTime;
    final now = DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(status).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, status),
              const SizedBox(height: 16),
              _buildTimeInfo(theme, startTime, endTime, now),
              const SizedBox(height: 12),
              _buildLocationInfo(theme),
              if (schedule['notes']?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildNotes(theme),
              ],
              const SizedBox(height: 16),
              _buildActions(theme, status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String status) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_boat,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule['bot_id'],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Schedule #${schedule['schedule_id']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        _buildStatusChip(status),
      ],
    );
  }

  Widget _buildTimeInfo(ThemeData theme, DateTime startTime, DateTime endTime, DateTime now) {
    final isActive = now.isAfter(startTime) && now.isBefore(endTime);
    final isUpcoming = startTime.isAfter(now);
    final duration = endTime.difference(startTime);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.play_circle : Icons.schedule,
                size: 16,
                color: isActive ? Colors.green : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Currently Running' : isUpcoming ? 'Scheduled' : 'Completed',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green : theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${duration.inHours}h ${duration.inMinutes % 60}m',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      _formatDateTime(startTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'End',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      _formatDateTime(endTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Text(
          'Coverage Area: ${schedule['area_radius_m']}m radius',
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        Icon(
          Icons.my_location,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Text(
          'View Map',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.note_outlined,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              schedule['notes'],
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme, String status) {
    final actions = _getAvailableActions(theme, status);
    final useIconButtons = actions.length >= 2;

    if (useIconButtons) {
      return Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            Expanded(
              child: _buildIconAction(theme, actions[i]),
            ),
            if (i < actions.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    } else {
      // Single action - keep original button style
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('View Details'),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildIconAction(ThemeData theme, Map<String, dynamic> action) {
    return InkWell(
      onTap: action['onPressed'],
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: action['color'].withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                action['icon'],
                size: 18,
                color: action['color'],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action['label'],
              style: theme.textTheme.labelSmall?.copyWith(
                color: action['color'],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableActions(ThemeData theme, String status) {
    final actions = <Map<String, dynamic>>[];
    
    // Always include view action
    actions.add({
      'icon': Icons.visibility_outlined,
      'label': 'View',
      'color': theme.colorScheme.primary,
      'onPressed': onView,
    });

    if (status == 'scheduled' && onEdit != null) {
      actions.add({
        'icon': Icons.edit_outlined,
        'label': 'Edit',
        'color': theme.colorScheme.primary,
        'onPressed': onEdit,
      });
      
      if (onCancel != null) {
        actions.add({
          'icon': Icons.cancel_outlined,
          'label': 'Cancel',
          'color': theme.colorScheme.error,
          'onPressed': onCancel,
        });
      }
    } else if (status == 'active' && onRecall != null) {
      actions.add({
        'icon': Icons.stop_circle_outlined,
        'label': 'Recall',
        'color': theme.colorScheme.error,
        'onPressed': onRecall,
      });
    }

    return actions;
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'active':
        return Icons.play_circle_filled;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (scheduleDate == today) {
      dateStr = 'Today';
    } else if (scheduleDate == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else if (scheduleDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }
    
    return '$dateStr ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
