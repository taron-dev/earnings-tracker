import 'package:earnings_tracker/app/app_routes.dart';
import 'package:earnings_tracker/app/today.dart';
import 'package:earnings_tracker/auth/auth_providers.dart';
import 'package:earnings_tracker/hourly_rate/hourly_rate_api.dart';
import 'package:earnings_tracker/overview/plan_overview_api.dart';
import 'package:earnings_tracker/plans/plans_api.dart';
import 'package:earnings_tracker/work_logs/work_log_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_hourly_rate_api.dart';
import 'fake_plan_overview_api.dart';
import 'fake_plans_api.dart';
import 'fake_work_log_api.dart';

/// 12 November 2026, the "today" of every widget test.
final testToday = DateTime(2026, 11, 12);

/// Runs the app's routes with in-memory APIs, without the Supabase sign-in redirect.
Future<GoRouter> pumpApp(
  WidgetTester tester, {
  String location = '/',
  FakeHourlyRateApi? hourlyRateApi,
  FakePlanOverviewApi? overviewApi,
  FakeWorkLogApi? workLogApi,
  FakePlansApi? plansApi,
}) async {
  // A tall phone screen, so a whole plan fits without scrolling.
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(navigatorKey: rootNavigatorKey, initialLocation: location, routes: appRoutes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(testToday),
        signedInEmailProvider.overrideWithValue('jana@example.com'),
        hourlyRateApiProvider.overrideWithValue(hourlyRateApi ?? FakeHourlyRateApi(eurPerHour('40.00'))),
        planOverviewApiProvider.overrideWithValue(overviewApi ?? FakePlanOverviewApi()),
        workLogApiProvider.overrideWithValue(workLogApi ?? FakeWorkLogApi()),
        plansApiProvider.overrideWithValue(plansApi ?? FakePlansApi()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String currentPath(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;
