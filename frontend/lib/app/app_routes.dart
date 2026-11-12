import 'package:go_router/go_router.dart';

import '../overview/overview_page.dart';
import '../settings/settings_page.dart';
import '../work_logs/work_logs_page.dart';
import 'app_shell.dart';

/// All routes of the app, without the sign-in redirect (that lives in `router.dart`),
/// so widget tests can build a router without Supabase.
final List<RouteBase> appRoutes = [
  GoRoute(path: '/', redirect: (context, state) => '/overview'),
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/overview',
            builder: (context, state) => const OverviewPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/work-logs',
            builder: (context, state) => const WorkLogsPage(),
          ),
        ],
      ),
    ],
  ),
  GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
];
