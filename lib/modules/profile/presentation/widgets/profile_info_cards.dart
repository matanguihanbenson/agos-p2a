import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';

class ProfileInfoCards extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileInfoCards({super.key, required this.userProfile});

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(
          title: 'Organization',
          value: userProfile.organization.isNotEmpty
              ? userProfile.organization
              : 'Not specified',
          icon: Icons.business_outlined,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Member Since',
          value: _formatDate(userProfile.createdAt),
          icon: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Last Updated',
          value: _formatDate(userProfile.updatedAt),
          icon: Icons.update_outlined,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Account Status',
          value: userProfile.isActive ? 'Active Account' : 'Inactive Account',
          icon: userProfile.isActive
              ? Icons.check_circle_outline
              : Icons.cancel_outlined,
          statusColor: userProfile.isActive
              ? Colors.green
              : theme.colorScheme.error,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? statusColor;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (statusColor ?? theme.colorScheme.primary).withOpacity(
                0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: statusColor ?? theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
