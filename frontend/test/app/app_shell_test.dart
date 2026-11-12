import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('opens on the overview tab with bottom navigation', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    expect(currentPath(router), '/overview');
    expect(find.widgetWithText(NavigationBar, 'Prehľad'), findsOneWidget);
    expect(find.widgetWithText(NavigationBar, 'Záznamy'), findsOneWidget);
    expect(find.widgetWithText(NavigationBar, 'Plány'), findsOneWidget);
  });

  testWidgets('switches to the plans tab', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Plány')));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/plans');
    expect(find.widgetWithText(AppBar, 'Plány'), findsOneWidget);
  });

  testWidgets('switches to the work log tab', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Záznamy')));
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
