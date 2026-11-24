import 'package:earnings_tracker/auth/auth_providers.dart';
import 'package:earnings_tracker/hourly_rate/hourly_rate_api.dart';
import 'package:earnings_tracker/settings/settings_page.dart';
import 'package:earnings_tracker/settings/theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_hourly_rate_api.dart';

Future<void> pumpSettings(WidgetTester tester, FakeHourlyRateApi api) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hourlyRateApiProvider.overrideWithValue(api),
        signedInEmailProvider.overrideWithValue('jana@example.com'),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get rateField => find.widgetWithText(TextField, 'Hodinová sadzba');

Finder get saveButton => find.widgetWithText(FilledButton, 'Uložiť');

String fieldText(WidgetTester tester) => tester.widget<TextField>(rateField).controller!.text;

void main() {
  testWidgets('shows the current rate without zero cents', (tester) async {
    await pumpSettings(tester, FakeHourlyRateApi(eurPerHour('40.00')));

    expect(fieldText(tester), '40');
  });

  testWidgets('leaves the field empty when no rate is set', (tester) async {
    await pumpSettings(tester, FakeHourlyRateApi());

    expect(fieldText(tester), '');
  });

  testWidgets('explains that a new rate applies only to new work', (tester) async {
    await pumpSettings(tester, FakeHourlyRateApi());

    expect(find.text('Nová sadzba platí len pre práce zapísané odteraz.'), findsOneWidget);
  });

  testWidgets('saves the typed rate', (tester) async {
    final api = FakeHourlyRateApi(eurPerHour('40.00'));
    await pumpSettings(tester, api);

    await tester.enterText(rateField, '42,5');
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(api.saved.single.perHour.toJson(), {'amount': '42.50', 'currency': 'EUR'});
    expect(find.text('Sadzba uložená.'), findsOneWidget);
    expect(fieldText(tester), '42,5');
  });

  testWidgets('cannot save an invalid rate', (tester) async {
    await pumpSettings(tester, FakeHourlyRateApi(eurPerHour('40.00')));

    for (final invalid in ['', '0', 'abc', '40,555']) {
      await tester.enterText(rateField, invalid);
      await tester.pump();

      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull, reason: '"$invalid"');
    }
  });

  testWidgets('keeps the typed rate when saving fails', (tester) async {
    final api = FakeHourlyRateApi(eurPerHour('40.00'))..failSaving = true;
    await pumpSettings(tester, api);

    await tester.enterText(rateField, '45');
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Uloženie zlyhalo.'), findsOneWidget);
    expect(fieldText(tester), '45');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('follows the system theme until another one is chosen', (tester) async {
    await pumpSettings(tester, FakeHourlyRateApi());

    final themes = tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>));
    expect(themes.selected, {ThemeMode.system});
  });

  testWidgets('switches to the dark theme and remembers it', (tester) async {
    await pumpSettings(tester, FakeHourlyRateApi());

    await tester.tap(find.text('Tmavý'));
    await tester.pumpAndSettle();

    final themes = tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>));
    expect(themes.selected, {ThemeMode.dark});
    expect((await SharedPreferences.getInstance()).getString('themeMode'), 'dark');
  });
}
