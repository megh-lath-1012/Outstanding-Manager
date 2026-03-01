import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../ui/scaffold_with_nav_bar.dart';

// Screens
import '../../ui/auth/splash_screen.dart';
import '../../ui/auth/login_screen.dart';
import '../../ui/auth/register_screen.dart';
import '../../ui/dashboard/dashboard_screen.dart';
import '../../ui/sales/sales_screen.dart';
import '../../ui/purchases/purchases_screen.dart';
import '../../ui/settings/settings_screen.dart';

// Navigator keys
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorSalesKey = GlobalKey<NavigatorState>(debugLabel: 'shellSales');
final _shellNavigatorPurchasesKey = GlobalKey<NavigatorState>(debugLabel: 'shellPurchases');
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isSplash = state.uri.path == '/';
      final isLogin = state.uri.path == '/login';
      final isRegister = state.uri.path == '/register';

      if (authState.isLoading) return null;

      if (!isAuth && !isLogin && !isRegister && !isSplash) {
        return '/login';
      }

      if (isAuth && (isLogin || isRegister || isSplash)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Sales
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSalesKey,
            routes: [
              GoRoute(
                path: '/sales',
                builder: (context, state) => const SalesScreen(),
              ),
            ],
          ),
          // Purchases
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPurchasesKey,
            routes: [
              GoRoute(
                path: '/purchases',
                builder: (context, state) => const PurchasesScreen(),
              ),
            ],
          ),
          // Settings
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
