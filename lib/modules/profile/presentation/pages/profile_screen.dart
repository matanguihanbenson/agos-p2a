import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/profile_providers.dart'; // Provider
import '../../domain/models/user_profile.dart'; // Model
import '../widgets/profile_header.dart'; // Header Widget
import '../widgets/profile_info_cards.dart'; // Info Cards
import '../widgets/settings_section.dart'; // SettingsSection Widget
import '../widgets/settings_item.dart'; // SettingsItem Model
import '../widgets/profile_dialogs.dart'; // All Dialogs

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
              // Refresh button
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                ProfileDialogs.showEditProfileDialog(context, userProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(userProfile: userProfile),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Account Settings',
              items: [
                SettingsItem(
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  icon: Icons.person_outline,
                  onTap: () => ProfileDialogs.showEditProfileDialog(
                    context,
                    userProfile,
                  ),
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
            Text(
              'Profile Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ProfileInfoCards(userProfile: userProfile),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Account Actions',
              items: [
                SettingsItem(
                  title: 'Export Data',
                  subtitle: 'Download your account data',
                  icon: Icons.download,
                  onTap: () => ProfileDialogs.exportData(context),
                ),
                SettingsItem(
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  icon: Icons.delete_forever,
                  onTap: () => ProfileDialogs.showDeleteAccountDialog(context),
                  isDestructive: true,
                ),
                SettingsItem(
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  icon: Icons.logout,
                  onTap: () => ProfileDialogs.showSignOutDialog(context),
                  isDestructive: true,
                ),
              ],
              titleColor: theme.colorScheme.error,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
