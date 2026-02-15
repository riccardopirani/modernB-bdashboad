import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/theme.dart';
import '../ui/shell/app_shell.dart';

// Simple router placeholder - will be extended
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      // App shell routes
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
            pageBuilder: (context, state) => const MaterialPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/properties',
            pageBuilder: (context, state) => const MaterialPage(
              child: PropertiesPage(),
            ),
          ),
          GoRoute(
            path: '/locks',
            pageBuilder: (context, state) => const MaterialPage(
              child: LocksPage(),
            ),
          ),
          GoRoute(
            path: '/bookings',
            pageBuilder: (context, state) => const MaterialPage(
              child: BookingsPage(),
            ),
          ),
          GoRoute(
            path: '/codes',
            pageBuilder: (context, state) => const MaterialPage(
              child: CodesPage(),
            ),
          ),
          GoRoute(
            path: '/guests',
            pageBuilder: (context, state) => const MaterialPage(
              child: GuestsPage(),
            ),
          ),
          GoRoute(
            path: '/integrations',
            pageBuilder: (context, state) => const MaterialPage(
              child: IntegrationsPage(),
            ),
          ),
          GoRoute(
            path: '/billing',
            pageBuilder: (context, state) => const MaterialPage(
              child: BillingPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const MaterialPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
    ],
  );
});

// Placeholder page widgets
class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Dashboard'),
      ),
    );
  }
}

class PropertiesPage extends StatelessWidget {
  const PropertiesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Properties'),
      ),
    );
  }
}

class LocksPage extends StatelessWidget {
  const LocksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Locks'),
      ),
    );
  }
}

class BookingsPage extends StatelessWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Bookings'),
      ),
    );
  }
}

class CodesPage extends StatelessWidget {
  const CodesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Codes'),
      ),
    );
  }
}

class GuestsPage extends StatelessWidget {
  const GuestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Guests'),
      ),
    );
  }
}

class IntegrationsPage extends StatelessWidget {
  const IntegrationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Integrations'),
      ),
    );
  }
}

class BillingPage extends StatelessWidget {
  const BillingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Billing'),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Settings'),
      ),
    );
  }
}
