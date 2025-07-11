import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class QuickActionsWidget extends StatelessWidget {
  final String userRole;
  const QuickActionsWidget({super.key, required this.userRole});

  void _handleActionTap(BuildContext context, String actionLabel) {
    switch (actionLabel) {
      case 'Live Feed':
        // Navigate to bot selection page for live feed
        Navigator.pushNamed(
          context,
          '/bot-selection',
          arguments: {'action': 'live-feed'},
        );
        break;
      case 'Control':
        Navigator.pushNamed(
          context,
          '/bot-selection',
          arguments: {'action': 'control'},
        );
        break;
      case 'Emergency Recall':
        Navigator.pushNamed(
          context,
          '/bot-selection',
          arguments: {'action': 'emergency-recall'},
        );
        break;
      case 'Assign Bot':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assign Bot feature coming soon')),
        );
        break;
      case 'Add Operator':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add Operator feature coming soon')),
        );
        break;
      case 'New Schedule':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Schedule feature coming soon')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$actionLabel feature coming soon')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = userRole == 'admin'
        ? [
            {
              'icon': Icons.undo_rounded,
              'label': 'Emergency Recall',
              'color': Colors.orange,
              'subtitle': 'Emergency',
            },
            {
              'icon': Icons.assignment_rounded,
              'label': 'Assign Bot',
              'color': Colors.blue,
              'subtitle': 'Reassign',
            },
            {
              'icon': Icons.person_add_rounded,
              'label': 'Add Operator',
              'color': Colors.green,
              'subtitle': 'New field',
            },
          ]
        : [
            {
              'icon': Icons.gamepad_rounded,
              'label': 'Control',
              'color': Colors.blue,
              'subtitle': 'Remote',
            },
            {
              'icon': Icons.schedule_rounded,
              'label': 'New Schedule',
              'color': Colors.purple,
              'subtitle': 'Task',
            },
            {
              'icon': Icons.videocam_rounded,
              'label': 'Live Feed',
              'color': Colors.red,
              'subtitle': 'Camera',
            },
          ];

    return Row(
      children: actions.map((action) {
        final index = actions.indexOf(action);
        return Expanded(
          child: Container(
            height: 100,
            margin: EdgeInsets.only(
              right: index == actions.length - 1 ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _handleActionTap(context, action['label'] as String);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          size: 20,
                          color: action['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['label'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
