import 'package:flutter/material.dart';
import 'routes/route_generator.dart';
import 'routes/app_routes.dart';
import 'data/firebase_initializer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agos/core/theme/theme.dart';
import 'modules/users/presentation/pages/add_field_operator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseInitializer.initialize();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGOS',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
