import 'package:flutter/material.dart';
import '../widgets/schedule_card.dart';
import '../widgets/schedule_filter_bar.dart';
import 'edit_schedule_screen.dart';
import 'create_schedule_screen.dart';
import 'view_schedule_screen.dart';

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
      'schedule_id': 'RCS-001',
      'bot_id': 'AGOS-001',
      'created_by': 'River Admin',
      'deployment_start': DateTime.now().add(const Duration(hours: 2)),
      'deployment_end': DateTime.now().add(const Duration(hours: 4)),
      'status': 'scheduled',
      'area_center': {
        'latitude': 13.4116,
        'longitude': 121.1825,
      }, // Calapan River
      'area_radius_m': 150,
      'docking_point': {'latitude': 13.4110, 'longitude': 121.1820},
      'notes':
          'Calapan River cleanup - Focus on plastic debris and water quality monitoring near city center',
      'created_at': DateTime.now().subtract(const Duration(days: 2)),
      'updated_at': DateTime.now().subtract(const Duration(hours: 1)),
    },
    {
      'schedule_id': 'RCS-002',
      'bot_id': 'AGOS-002',
      'created_by': 'Environmental Officer',
      'deployment_start': DateTime.now().subtract(const Duration(hours: 1)),
      'deployment_end': DateTime.now().add(const Duration(hours: 1)),
      'status': 'active',
      'area_center': {
        'latitude': 13.3694,
        'longitude': 121.0889,
      }, // Bucayao River
      'area_radius_m': 200,
      'docking_point': {'latitude': 13.3690, 'longitude': 121.0885},
      'notes':
          'Bucayao River section - High priority cleanup due to recent pollution reports and agricultural runoff',
      'created_at': DateTime.now().subtract(const Duration(days: 1)),
      'updated_at': DateTime.now().subtract(const Duration(minutes: 30)),
    },
    {
      'schedule_id': 'RCS-003',
      'bot_id': 'AGOS-003',
      'created_by': 'Water Quality Team',
      'deployment_start': DateTime.now().subtract(const Duration(hours: 3)),
      'deployment_end': DateTime.now().subtract(const Duration(hours: 1)),
      'status': 'completed',
      'area_center': {
        'latitude': 13.3167,
        'longitude': 121.1167,
      }, // Naujan Lake
      'area_radius_m': 300,
      'docking_point': {'latitude': 13.3160, 'longitude': 121.1160},
      'notes':
          'Naujan Lake cleanup completed - Collected 18kg of debris, pH levels stable, turbidity within normal range',
      'created_at': DateTime.now().subtract(const Duration(days: 3)),
      'updated_at': DateTime.now().subtract(const Duration(hours: 1)),
      'completed_at': DateTime.now().subtract(const Duration(hours: 1)),
    },
    {
      'schedule_id': 'RCS-004',
      'bot_id': 'AGOS-001',
      'created_by': 'River Admin',
      'deployment_start': DateTime.now().subtract(const Duration(days: 1)),
      'deployment_end': DateTime.now().subtract(
        const Duration(days: 1, hours: -2),
      ),
      'status': 'cancelled',
      'area_center': {
        'latitude': 13.4050,
        'longitude': 121.1750,
      }, // Calapan River (different section)
      'area_radius_m': 120,
      'docking_point': {'latitude': 13.4045, 'longitude': 121.1745},
      'notes':
          'Calapan River upper section - Cancelled due to severe weather conditions and dangerous water levels',
      'created_at': DateTime.now().subtract(const Duration(days: 2)),
      'updated_at': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'River Cleanup Schedules',
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
            tooltip: 'Refresh cleanup schedules',
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
        label: const Text('New Cleanup'),
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
        message = 'No scheduled river cleanups';
        icon = Icons.schedule_outlined;
        break;
      case 'active':
        message = 'No active cleanup operations';
        icon = Icons.play_circle_outline;
        break;
      case 'completed':
        message = 'No completed cleanup operations';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'No cancelled cleanup operations';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No cleanup schedules found';
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
                ? 'Schedule your first river cleanup to get started'
                : 'Try adjusting your filters or schedule a new cleanup',
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
              label: const Text('Schedule Cleanup'),
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
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ViewScheduleScreen(schedule: schedule),
          ),
        )
        .then((result) {
          if (result == true) {
            // Schedule was modified, refresh the list
            _refreshSchedules();
          }
        });
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
        title: const Text('Cancel Cleanup'),
        content: Text(
          'Are you sure you want to cancel the river cleanup schedule for ${schedule['bot_id']}?',
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
                const SnackBar(content: Text('Cleanup schedule cancelled')),
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
        title: const Text('Return Bot'),
        content: Text(
          'Are you sure you want to return ${schedule['bot_id']} to base? This will stop the current cleanup operation.',
        ),
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
                const SnackBar(content: Text('Bot returned successfully')),
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
          content: Text('Cleanup schedules refreshed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
