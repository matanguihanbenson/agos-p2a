import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/user_providers.dart';
import '../../../../core/models/user_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_cards.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_item.dart';
import '../widgets/profile_dialogs.dart';

import '../widgets/impact/impact_header.dart';
import '../widgets/impact/trash_collection_metrics.dart';
import '../widgets/impact/water_quality.dart';
import '../widgets/impact/operations_metrics.dart';
import '../widgets/impact/trends_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (userProfile) {
        if (userProfile == null) {
          return const Scaffold(
            body: Center(child: Text('User profile not found')),
          );
        }
        return _ProfileBody(userProfile: userProfile);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Unable to load profile'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.refresh(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile userProfile;
  const _ProfileBody({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.eco), text: 'Impact'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
              Tab(icon: Icon(Icons.help), text: 'Support'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfileTab(userProfile: userProfile),
            _ImpactTab(),
            _SettingsTab(userProfile: userProfile),
            _SupportTab(),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final UserProfile userProfile;
  const _ProfileTab({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeader(userProfile: userProfile),
          const SizedBox(height: 24),

          const SizedBox(height: 24),

          ProfileInfoCards(userProfile: userProfile),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final UserProfile userProfile;
  const _SettingsTab({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SettingsSection(
            title: 'Preferences',
            items: [
              SettingsItem(
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                icon: Icons.notifications_outlined,
                onTap: () {
                  // TODO: Add notification settings
                },
              ),
              SettingsItem(
                title: 'Privacy',
                subtitle: 'Control your privacy settings',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  // TODO: Add privacy settings
                },
              ),
              SettingsItem(
                title: 'Change Password',
                subtitle: 'Update your account password',
                icon: Icons.lock_outline,
                onTap: () => ProfileDialogs.showChangePasswordDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SettingsSection(
            title: 'Data & Privacy',
            items: [
              SettingsItem(
                title: 'Export Data',
                subtitle: 'Download your account data',
                icon: Icons.download,
                onTap: () => ProfileDialogs.exportData(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SupportTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SettingsSection(
            title: 'Help & Support',
            items: [
              SettingsItem(
                title: 'Help Center',
                subtitle: 'Get help and find answers',
                icon: Icons.help_outline,
                onTap: () => ProfileDialogs.showHelpCenter(context),
              ),
              SettingsItem(
                title: 'Contact Support',
                subtitle: 'Reach out to our support team',
                icon: Icons.support_agent,
                onTap: () => ProfileDialogs.contactSupport(context),
              ),
              SettingsItem(
                title: 'Report a Bug',
                subtitle: 'Help us improve the app',
                icon: Icons.bug_report,
                onTap: () => ProfileDialogs.reportBug(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ImpactTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImpactHeader(),
          const SizedBox(height: 24),
          TrashCollectionMetrics(),
          const SizedBox(height: 24),

          WaterQualityMetrics(),
          const SizedBox(height: 24),
          OperationsMetrics(),
          const SizedBox(height: 24),
          TrendsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
