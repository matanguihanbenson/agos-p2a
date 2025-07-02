import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modules/auth/presentation/pages/login_page.dart';
import '../core/widgets/navigation/bottom_navigation.dart';

import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) =>
              isLoggedIn ? const BottomNavigation() : const LoginPage(),
        );

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const BottomNavigation());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('No route defined'))),
        );
    }
  }
}
