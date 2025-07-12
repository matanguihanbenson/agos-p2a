import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/location_display_widget.dart';
import 'edit_schedule_screen.dart';
import 'map_location_picker.dart';

class ViewScheduleScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;

  const ViewScheduleScreen({super.key, required this.schedule});

  @override
  State<ViewScheduleScreen> createState() => _ViewScheduleScreenState();
}

class _ViewScheduleScreenState extends State<ViewScheduleScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = widget.schedule;
    final status = schedule['status'] as String;
    final startTime = schedule['deployment_start'] as DateTime;
    final endTime = schedule['deployment_end'] as DateTime;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('Cleanup Schedule #${schedule['schedule_id']}'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (status == 'scheduled')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editSchedule,
              tooltip: 'Edit cleanup schedule',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share, size: 18),
                    const SizedBox(width: 8),
                    const Text('Share Details'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy_id',
                child: Row(
                  children: [
                    const Icon(Icons.copy, size: 18),
                    const SizedBox(width: 8),
                    const Text('Copy Schedule ID'),
                  ],
                ),
              ),
              if (status == 'scheduled') ...[
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      const Icon(Icons.content_copy, size: 18),
                      const SizedBox(width: 8),
                      const Text('Duplicate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cancel Cleanup',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
              if (status == 'active')
                PopupMenuItem(
                  value: 'recall',
                  child: Row(
                    children: [
                      Icon(
                        Icons.stop_circle,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Return Bot',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(
              theme,
              schedule,
              status,
              now,
              startTime,
              endTime,
            ),
            const SizedBox(height: 24),
            _buildBotInfoSection(theme, schedule),
            const SizedBox(height: 24),
            _buildScheduleSection(theme, schedule, startTime, endTime, now),
            const SizedBox(height: 24),
            _buildLocationSection(theme, schedule),
            if (schedule['docking_point'] != null) ...[
              const SizedBox(height: 24),
              _buildDockingPointSection(theme, schedule),
            ],
            if (schedule['notes']?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              _buildNotesSection(theme, schedule),
            ],
            const SizedBox(height: 24),
            _buildMetadataSection(theme, schedule),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(theme, status),
    );
  }

  Widget _buildHeaderSection(
    ThemeData theme,
    Map<String, dynamic> schedule,
    String status,
    DateTime now,
    DateTime startTime,
    DateTime endTime,
  ) {
    final isActive = now.isAfter(startTime) && now.isBefore(endTime);
    final isUpcoming = startTime.isAfter(now);
    final progress = _calculateProgress(now, startTime, endTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor(status).withOpacity(0.1),
            _getStatusColor(status).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
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
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusDescription(status, isActive, isUpcoming),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isActive && progress != null) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cleanup Progress',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(_getStatusColor(status)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotInfoSection(ThemeData theme, Map<String, dynamic> schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'River Cleanup Bot',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Bot ID',
            schedule['bot_id'],
            Icons.smart_toy,
            theme,
            isCopyable: true,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Schedule ID',
            schedule['schedule_id'],
            Icons.assignment,
            theme,
            isCopyable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(
    ThemeData theme,
    Map<String, dynamic> schedule,
    DateTime startTime,
    DateTime endTime,
    DateTime now,
  ) {
    final duration = endTime.difference(startTime);
    final timeUntilStart = startTime.difference(now);
    final timeRemaining = endTime.difference(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cleanup Schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  'Start Time',
                  _formatFullDateTime(startTime),
                  Icons.play_circle_outline,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeCard(
                  'End Time',
                  _formatFullDateTime(endTime),
                  Icons.stop_circle,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Operation Duration',
            _formatDuration(duration),
            Icons.timer,
            theme,
          ),
          if (timeUntilStart.inSeconds > 0) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Cleanup Starts In',
              _formatDuration(timeUntilStart),
              Icons.hourglass_top,
              theme,
            ),
          ] else if (timeRemaining.inSeconds > 0) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Time Remaining',
              _formatDuration(timeRemaining),
              Icons.hourglass_bottom,
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection(ThemeData theme, Map<String, dynamic> schedule) {
    final areaCenter = schedule['area_center'];
    final radius = schedule['area_radius_m'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'River Cleanup Zone',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _viewOnMap,
              icon: const Icon(Icons.map, size: 16),
              label: const Text('View on Map'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Water area designated for trash collection and quality monitoring',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        LocationDisplayWidget(
          latitude: areaCenter['latitude'],
          longitude: areaCenter['longitude'],
          radius: radius,
          title: 'Cleanup Coverage Area',
          icon: Icons.water_drop,
          showRadius: true,
        ),
      ],
    );
  }

  Widget _buildDockingPointSection(
    ThemeData theme,
    Map<String, dynamic> schedule,
  ) {
    final dockingPoint = schedule['docking_point'];
    if (dockingPoint == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Return Station',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bot will return here after completing cleanup operations',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        LocationDisplayWidget(
          latitude: dockingPoint['latitude'],
          longitude: dockingPoint['longitude'],
          title: 'Return Station',
          icon: Icons.home_work,
          showRadius: false,
        ),
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme, Map<String, dynamic> schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note,
                color: theme.colorScheme.onSecondaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Operation Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            schedule['notes'],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(ThemeData theme, Map<String, dynamic> schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Metadata',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (schedule['created_at'] != null)
            _buildInfoRow(
              'Created',
              _formatFullDateTime(schedule['created_at']),
              Icons.event,
              theme,
            ),
          if (schedule['updated_at'] != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Last Updated',
              _formatFullDateTime(schedule['updated_at']),
              Icons.update,
              theme,
            ),
          ],
          if (schedule['completed_at'] != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Completed',
              _formatFullDateTime(schedule['completed_at']),
              Icons.check_circle,
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    bool isCopyable = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        if (isCopyable)
          IconButton(
            onPressed: () => _copyToClipboard(value),
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy $label',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildTimeCard(
    String label,
    String time,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (status == 'scheduled') ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editSchedule,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cancelSchedule,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else if (status == 'active') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _recallBot,
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('Recall Bot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _duplicateSchedule,
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Duplicate'),
                ),
              ),
            ],
          ],
        ),
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

  String _getStatusDescription(String status, bool isActive, bool isUpcoming) {
    switch (status) {
      case 'scheduled':
        return isUpcoming
            ? 'River cleanup is scheduled'
            : 'Ready for cleanup operation';
      case 'active':
        return 'Bot is currently cleaning and monitoring water quality';
      case 'completed':
        return 'Cleanup operation completed successfully';
      case 'cancelled':
        return 'Cleanup operation was cancelled';
      default:
        return 'Unknown status';
    }
  }

  double? _calculateProgress(DateTime now, DateTime start, DateTime end) {
    if (now.isBefore(start)) return null;
    if (now.isAfter(end)) return 1.0;

    final total = end.difference(start).inMinutes;
    final elapsed = now.difference(start).inMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatFullDateTime(DateTime dateTime) {
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
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    return '$dateStr at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Expired';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareScheduleDetails();
        break;
      case 'copy_id':
        _copyToClipboard(widget.schedule['schedule_id']);
        break;
      case 'duplicate':
        _duplicateSchedule();
        break;
      case 'cancel':
        _cancelSchedule();
        break;
      case 'recall':
        _recallBot();
        break;
    }
  }

  void _shareScheduleDetails() {
    final schedule = widget.schedule;
    final text =
        '''
River Cleanup Schedule
ID: ${schedule['schedule_id']}
Bot: ${schedule['bot_id']}
Status: ${schedule['status'].toString().toUpperCase()}
Start: ${_formatFullDateTime(schedule['deployment_start'])}
End: ${_formatFullDateTime(schedule['deployment_end'])}
Cleanup Zone: ${schedule['area_center']['latitude']}, ${schedule['area_center']['longitude']}
Coverage Radius: ${schedule['area_radius_m']}m
Operation: Trash Collection & Water Quality Monitoring
''';

    // TODO: Implement actual sharing functionality
    _copyToClipboard(text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cleanup schedule details copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewOnMap() {
    final areaCenter = widget.schedule['area_center'];
    final radius = widget.schedule['area_radius_m'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: areaCenter['latitude'],
          initialLongitude: areaCenter['longitude'],
          coverageRadius: radius,
          title: 'River Cleanup Zone',
          showCoverageCircle: true,
        ),
      ),
    );
  }

  void _editSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScheduleScreen(schedule: widget.schedule),
      ),
    ).then((result) {
      if (result == true) {
        // Schedule was updated, refresh or navigate back
        Navigator.pop(context, true);
      }
    });
  }

  void _duplicateSchedule() {
    // TODO: Navigate to create schedule with pre-filled data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate schedule feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelSchedule() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Cleanup'),
        content: Text(
          'Are you sure you want to cancel this river cleanup schedule for ${widget.schedule['bot_id']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cleanup schedule cancelled successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _recallBot() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Bot'),
        content: Text(
          'Are you sure you want to return ${widget.schedule['bot_id']}? This will stop the current cleanup operation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bot returned successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Yes, Return'),
          ),
        ],
      ),
    );
  }
}
