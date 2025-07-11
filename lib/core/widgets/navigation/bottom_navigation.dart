import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agos/modules/dashboard/presentation/pages/homepage.dart';
import 'package:agos/modules/map/presentation/pages/map_screen.dart';
import 'package:agos/modules/bot/presentation/pages/bot_screen.dart';
import 'package:agos/modules/users/presentation/pages/users_screen.dart';
import 'package:agos/modules/schedule/presentation/pages/schedule_screen.dart';
import 'package:agos/modules/profile/presentation/pages/profile_screen.dart';

import '../../providers/nav_provider.dart';
import '../../providers/user_providers.dart';

class BottomNavigation extends ConsumerWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRoleAsync = ref.watch(userRoleProvider);

    return userRoleAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Error loading role: $error'))),
      data: (role) {
        // Wait for authentication before building screens
        if (uid == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Authenticating...'),
                ],
              ),
            ),
          );
        }

        // Build your screens based on role
        final screens = role == 'admin'
            ? [
                const MapScreen(),
                BotScreen(role: role),
                const HomePage(),
                const UsersScreen(),
                const ProfileScreen(),
              ]
            : [
                const MapScreen(),
                BotScreen(role: role),
                const HomePage(),
                const ScheduleScreen(),
                const ProfileScreen(),
              ];

        final adjustedIndex = currentIndex >= screens.length ? 0 : currentIndex;

        final navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat),
            label: 'Bots',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(role == 'admin' ? Icons.people : Icons.schedule),
            label: role == 'admin' ? 'Users' : 'Schedule',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        return Scaffold(
          body: IndexedStack(index: adjustedIndex, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: adjustedIndex,
            onTap: (index) {
              ref.read(bottomNavIndexProvider.notifier).state = index;
            },
            selectedFontSize: 10,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: navItems,
          ),
        );
      },
    );
  }
}
