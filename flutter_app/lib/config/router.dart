import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockflow/ui/shell/app_shell.dart';
import 'package:lockflow/features/dashboard/dashboard_page.dart';
import 'package:lockflow/features/properties/properties_page.dart';
import 'package:lockflow/features/locks/locks_page.dart';
import 'package:lockflow/features/bookings/bookings_page.dart';
import 'package:lockflow/features/codes/codes_page.dart';
import 'package:lockflow/features/integrations/integrations_page.dart';
import 'package:lockflow/features/billing/billing_page.dart';
import 'package:lockflow/features/settings/settings_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/properties',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const PropertiesPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/locks',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const LocksPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/bookings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const BookingsPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/codes',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CodesPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/integrations',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const IntegrationsPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/billing',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const BillingPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),
    ],
  );
});

// Smooth fade + slide transition for page navigation
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.02, 0),
        end: Offset.zero,
      ).animate(CurveTween(curve: Curves.easeOut).animate(animation)),
      child: child,
    ),
  );
}
