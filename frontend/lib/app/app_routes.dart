import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../overview/overview_page.dart';
import '../plans/plan_detail_page.dart';
import '../plans/plan_form_page.dart';
import '../plans/plans_page.dart';
import '../settings/settings_page.dart';
import '../work_logs/work_logs_page.dart';
import 'app_shell.dart';

/// The navigator above the bottom navigation; full-screen forms open on it.
final rootNavigatorKey = GlobalKey<NavigatorState>();

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
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/plans',
            builder: (context, state) => const PlansPage(),
            routes: [
              // Before `:id`, so "new" is not taken for a plan id.
              GoRoute(
                path: 'new',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const PlanFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => PlanDetailPage(planId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => PlanFormPage(planId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
];
