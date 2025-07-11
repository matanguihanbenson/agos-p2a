import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/auth/presentation/pages/login_page.dart';
import '../modules/auth/presentation/pages/signup_page.dart';
import '../modules/auth/presentation/pages/splash_page.dart';
import '../core/widgets/navigation/bottom_navigation.dart';
import '../modules/bot/presentation/pages/bot_details.dart';
import '../modules/bot/presentation/pages/live_feed_screen.dart';
import '../modules/bot/presentation/pages/bot_list_page.dart'; // Add this import
import '../modules/bot/presentation/pages/bot_control_screen.dart'; // Add this import
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const BottomNavigation());

      case AppRoutes.liveFeed:
        final botDoc = settings.arguments as DocumentSnapshot<Object?>?;
        if (botDoc != null) {
          return MaterialPageRoute(
            builder: (_) => LiveFeedScreen(botDoc: botDoc),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Bot data required'))),
        );

      case AppRoutes.botList:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => BotListPage(arguments: args));

      // Add new route for bot selection
      case AppRoutes.botSelection:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => BotListPage(arguments: args));

      // Add bot control route
      case AppRoutes.botControl:
        final botDoc = settings.arguments as DocumentSnapshot<Object?>?;
        if (botDoc != null) {
          return MaterialPageRoute(
            builder: (_) => BotControlScreen(botDoc: botDoc),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Bot data required'))),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('No route defined'))),
        );
    }
  }
}
