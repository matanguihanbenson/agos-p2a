import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/user_model.dart';
import 'info_chip.dart';
import 'profile_dialogs.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        // Main Profile Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar and Name Section
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: user == null
                          ? null
                          : FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots(),
                      builder: (context, snapshot) {
                        String initials = userProfile.initials;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (data != null) {
                            final firstName = data['firstname'] ?? '';
                            final lastName = data['lastname'] ?? '';
                            if (firstName.isNotEmpty && lastName.isNotEmpty) {
                              initials = '${firstName[0]}${lastName[0]}'
                                  .toUpperCase();
                            } else if (firstName.isNotEmpty) {
                              initials = firstName[0].toUpperCase();
                            }
                          }
                        }

                        return Center(
                          child: Text(
                            initials,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                              fontSize: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Name and Email
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: user == null
                          ? null
                          : FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots(),
                      builder: (context, snapshot) {
                        String fullName = userProfile.fullName;
                        String email = userProfile.email;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (data != null) {
                            final firstName = data['firstname'] ?? '';
                            final lastName = data['lastname'] ?? '';
                            fullName = '$firstName $lastName'.trim();
                            if (fullName.isEmpty) fullName = 'User';
                            email = data['email'] ?? userProfile.email;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Status Chips
              StreamBuilder<DocumentSnapshot>(
                stream: user == null
                    ? null
                    : FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                builder: (context, snapshot) {
                  String role = userProfile.role;
                  bool isActive = userProfile.isActive;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      role = data['role'] ?? userProfile.role;
                      isActive = data['isActive'] ?? userProfile.isActive;
                    }
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InfoChip(
                        label: role.toUpperCase(),
                        color: role == 'admin'
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      InfoChip(
                        label: isActive ? 'ACTIVE' : 'INACTIVE',
                        color: isActive
                            ? Colors.green
                            : theme.colorScheme.error,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Edit Profile',
                icon: Icons.edit_outlined,
                isPrimary: true,
                onTap: () =>
                    ProfileDialogs.showEditProfileDialog(context, userProfile),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionButton(
                label: 'Sign Out',
                icon: Icons.logout_outlined,
                isPrimary: false,
                isDestructive: true,
                onTap: () => ProfileDialogs.showSignOutDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary
                ? null
                : isDestructive
                ? theme.colorScheme.errorContainer.withOpacity(0.1)
                : theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : isDestructive
                  ? theme.colorScheme.error.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? theme.colorScheme.onPrimary
                    : isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
