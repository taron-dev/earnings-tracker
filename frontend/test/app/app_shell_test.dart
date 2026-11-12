import 'package:earnings_tracker/app/app_routes.dart';
import 'package:earnings_tracker/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's routes without the Supabase sign-in redirect and without Supabase itself.
Future<GoRouter> pumpApp(WidgetTester tester, {String location = '/'}) async {
  final router = GoRouter(initialLocation: location, routes: appRoutes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [signedInEmailProvider.overrideWithValue('jana@example.com')],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('opens on the overview tab with bottom navigation', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    expect(currentPath(router), '/overview');
    expect(find.widgetWithText(NavigationBar, 'Prehľad'), findsOneWidget);
    expect(find.widgetWithText(NavigationBar, 'Záznamy'), findsOneWidget);
  });

  testWidgets('switches to the work log tab', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.widgetWithText(NavigationBar, 'Záznamy'));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/work-logs');
    expect(find.widgetWithText(AppBar, 'Záznamy práce'), findsOneWidget);
  });

  testWidgets('opens settings from the app bar and goes back', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.byTooltip('Nastavenia'));
    await tester.pumpAndSettle();
    // Pushed on top of the tab, so the browser URL stays /overview (go_router default).
    expect(find.widgetWithText(AppBar, 'Nastavenia'), findsOneWidget);
    expect(find.text('Prihlásený: jana@example.com'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(currentPath(router), '/overview');
  });
}
