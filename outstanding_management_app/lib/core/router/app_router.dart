import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../scaffold_with_nav_bar.dart';

// Screens
import '../auth/splash_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../invoices/invoices_screen.dart';
import '../parties/parties_screen.dart';
import '../payments/payments_screen.dart';
import '../profile/profile_screen.dart';

// Navigator keys
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final _shellNavigatorInvoicesKey = GlobalKey<NavigatorState>(debugLabel: 'shellInvoices');
final _shellNavigatorPartiesKey = GlobalKey<NavigatorState>(debugLabel: 'shellParties');
final _shellNavigatorPaymentsKey = GlobalKey<NavigatorState>(debugLabel: 'shellPayments');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Logic for authenticated routes protection
      final isAuth = authState.value != null;
      final isSplash = state.uri.path == '/';
      final isLogin = state.uri.path == '/login';
      final isRegister = state.uri.path == '/register';

      // If still loading auth state, stay on splash
      if (authState.isLoading) return null;

      if (!isAuth && !isLogin && !isRegister && !isSplash) {
        return '/login';
      }

      if (isAuth && (isLogin || isRegister || isSplash)) {
        return '/dashboard';
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
      // Stateful navigation shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // The dashboard branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // The invoices branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInvoicesKey,
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoicesScreen(),
              ),
            ],
          ),
          // The parties branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPartiesKey,
            routes: [
              GoRoute(
                path: '/parties',
                builder: (context, state) => const PartiesScreen(),
              ),
            ],
          ),
          // The payments branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPaymentsKey,
            routes: [
              GoRoute(
                path: '/payments',
                builder: (context, state) => const PaymentsScreen(),
              ),
            ],
          ),
          // The profile branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
