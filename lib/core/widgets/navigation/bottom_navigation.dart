import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agos/modules/dashboard/presentation/pages/homepage.dart';
import 'package:agos/modules/map/presentation/pages/map_screen.dart';
import 'package:agos/modules/bot/presentation/pages/bot_screen.dart';
import 'package:agos/modules/notifications/presentation/pages/notification_screen.dart';

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
        // Build your screens, passing uid & role into BotScreen
        final screens = [
          const MapScreen(),
          // Pass the required args here:
          BotScreen(role: role),
          const HomePage(),
          const NotificationScreen(),
          // const ImpactScreen(),
        ];

        final adjustedIndex = currentIndex >= screens.length ? 0 : currentIndex;

        final navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.directions_boat),
            label: 'Bots', // changed from 'Boats'
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(uid)
                  .collection('userNotifications')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.docs.length ?? 0;
                return badges.Badge(
                  showBadge: unreadCount > 0,
                  badgeContent: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: const Icon(Icons.notifications),
                );
              },
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Impact',
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
