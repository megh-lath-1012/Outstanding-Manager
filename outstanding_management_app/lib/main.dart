import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase, but catch errors if configuration is missing
  // This allows the UI to build even if the user hasn't run flutterfire configure yet
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed or not configured yet. Run flutterfire configure. Error: $e");
  }

  runApp(
    const ProviderScope(
      child: OutstandingApp(),
    ),
  );
}

class OutstandingApp extends ConsumerWidget {
  const OutstandingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Outstanding Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
