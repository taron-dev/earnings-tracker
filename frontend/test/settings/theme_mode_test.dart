import 'package:earnings_tracker/settings/theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> containerWith(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('follows the system until a theme is chosen', () async {
    final container = await containerWith({});

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('starts with the saved theme', () async {
    final container = await containerWith({'themeMode': 'dark'});

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('ignores an unknown saved value', () async {
    final container = await containerWith({'themeMode': 'sepia'});

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('saves the chosen theme', () async {
    final container = await containerWith({});

    await container.read(themeModeProvider.notifier).choose(ThemeMode.light);

    expect(container.read(themeModeProvider), ThemeMode.light);
    expect((await SharedPreferences.getInstance()).getString('themeMode'), 'light');
  });
}
