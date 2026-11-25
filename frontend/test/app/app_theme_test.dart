import 'package:earnings_tracker/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('the app bar keeps the background color when content scrolls under it (${brightness.name})', (
      tester,
    ) async {
      final theme = appTheme(brightness);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Prehľad')),
            body: ListView(children: [for (var i = 0; i < 50; i++) ListTile(title: Text('Riadok $i'))]),
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final bar = tester.widget<Material>(
        find.descendant(of: find.byType(AppBar), matching: find.byType(Material)).first,
      );
      expect(bar.color, theme.scaffoldBackgroundColor);
      expect(bar.elevation, 0);
    });
  }

  test('both themes carry their own set of redesign colors', () {
    expect(appTheme(Brightness.light).extension<AppColors>(), AppColors.light);
    expect(appTheme(Brightness.dark).extension<AppColors>(), AppColors.dark);
    expect(appTheme(Brightness.light).scaffoldBackgroundColor, AppColors.light.background);
    expect(appTheme(Brightness.dark).scaffoldBackgroundColor, AppColors.dark.background);
  });

  test('text uses the bundled font with tabular figures', () {
    final style = appTheme(Brightness.light).textTheme.bodyMedium!;
    expect(style.fontFamily, appFontFamily);
    expect(style.fontFeatures, tabularFigures);
  });
}
