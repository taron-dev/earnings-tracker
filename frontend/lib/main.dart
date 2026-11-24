import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_theme.dart';
import 'app/max_width_layout.dart';
import 'config.dart';
import 'router.dart';
import 'settings/theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs;
  try {
    Config.ensureComplete();
    prefs = await SharedPreferences.getInstance();

    // Also picks up the session from the redirect URL after Google / magic link sign-in.
    await Supabase.initialize(
      url: Config.supabaseUrl,
      publishableKey: Config.supabasePublishableKey,
    );
  } catch (e) {
    // Without this a broken deploy is just a blank white page.
    runApp(_StartupErrorApp(error: e));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const EarningsTrackerApp(),
    ),
  );
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Aplikáciu sa nepodarilo spustiť:\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class EarningsTrackerApp extends ConsumerWidget {
  const EarningsTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Earnings Tracker',
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      builder: (context, child) => MaxWidthLayout(child: child!),
      // Slovak only for now; flutter_localizations makes the date picker Slovak and start weeks on Monday.
      locale: const Locale('sk'),
      supportedLocales: const [Locale('sk')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
