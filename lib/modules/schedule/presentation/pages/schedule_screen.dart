import 'package:flutter/material.dart';
import '../widgets/schedule_card.dart';
import '../widgets/schedule_filter_bar.dart';
import 'edit_schedule_screen.dart';
import 'create_schedule_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = false;

  // Mock data - replace with actual Firestore data
  final List<Map<String, dynamic>> _schedules = [
    {
      'schedule_id': '1',
      'bot_id': 'BOT-001',
      'created_by': 'user123',
      'deployment_start': DateTime.now().add(const Duration(hours: 2)),
      'deployment_end': DateTime.now().add(const Duration(hours: 4)),
      'status': 'scheduled',
      'area_center': {'latitude': 14.5995, 'longitude': 120.9842},
      'area_radius_m': 100,
      'notes': 'Main plaza cleaning - Regular maintenance schedule',
    },
    {
      'schedule_id': '2',
      'bot_id': 'BOT-002',
      'created_by': 'user456',
      'deployment_start': DateTime.now().subtract(const Duration(hours: 1)),
      'deployment_end': DateTime.now().add(const Duration(hours: 1)),
      'status': 'active',
      'area_center': {'latitude': 14.6042, 'longitude': 120.9822},
      'area_radius_m': 150,
      'notes': 'Park area maintenance - High traffic zone',
    },
    {
      'schedule_id': '3',
      'bot_id': 'BOT-003',
      'created_by': 'user789',
      'deployment_start': DateTime.now().subtract(const Duration(hours: 3)),
      'deployment_end': DateTime.now().subtract(const Duration(hours: 1)),
      'status': 'completed',
      'area_center': {'latitude': 14.6000, 'longitude': 120.9800},
      'area_radius_m': 80,
      'notes': 'Street cleaning completed successfully',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Schedule Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_outlined),
            onPressed: _isLoading ? null : _refreshSchedules,
            tooltip: 'Refresh schedules',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          ScheduleFilterBar(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            schedules: _schedules,
          ),
          Expanded(child: _buildScheduleList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewSchedule,
        icon: const Icon(Icons.add),
        label: const Text('New Schedule'),
      ),
    );
  }

  Widget _buildScheduleList() {
    final filteredSchedules = _selectedFilter == 'all'
        ? _schedules
        : _schedules.where((s) => s['status'] == _selectedFilter).toList();

    if (filteredSchedules.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: filteredSchedules.length,
      itemBuilder: (context, index) {
        final schedule = filteredSchedules[index];
        return ScheduleCard(
          schedule: schedule,
          onView: () => _viewScheduleDetails(schedule),
          onEdit: schedule['status'] == 'scheduled'
              ? () => _editSchedule(schedule)
              : null,
          onCancel: schedule['status'] == 'scheduled'
              ? () => _cancelSchedule(schedule)
              : null,
          onRecall: schedule['status'] == 'active'
              ? () => _recallBot(schedule)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case 'scheduled':
        message = 'No scheduled deployments';
        icon = Icons.schedule_outlined;
        break;
      case 'active':
        message = 'No active deployments';
        icon = Icons.play_circle_outline;
        break;
      case 'completed':
        message = 'No completed deployments';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'No cancelled deployments';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No schedules found';
        icon = Icons.schedule_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Create your first schedule to get started'
                : 'Try adjusting your filters or create a new schedule',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedFilter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewSchedule,
              icon: const Icon(Icons.add),
              label: const Text('Create Schedule'),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // Implement filter dialog
  }

  void _createNewSchedule() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const CreateScheduleScreen()),
        )
        .then((result) {
          if (result == true) {
            // Schedule was created, refresh the list
            _refreshSchedules();
          }
        });
  }

  void _viewScheduleDetails(Map<String, dynamic> schedule) {
    // Navigate to schedule details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${schedule['bot_id']}')),
    );
  }

  void _editSchedule(Map<String, dynamic> schedule) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditScheduleScreen(schedule: schedule),
          ),
        )
        .then((result) {
          if (result == true) {
            // Schedule was updated, refresh the list
            _refreshSchedules();
          }
        });
  }

  void _cancelSchedule(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Schedule'),
        content: Text(
          'Are you sure you want to cancel the schedule for ${schedule['bot_id']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement cancel logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule cancelled')),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _recallBot(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recall Bot'),
        content: Text('Are you sure you want to recall ${schedule['bot_id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement recall logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bot recalled successfully')),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSchedules() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedules refreshed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
