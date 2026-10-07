import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    Config.ensureComplete();

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

  runApp(const EarningsTrackerApp());
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

class EarningsTrackerApp extends StatelessWidget {
  const EarningsTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Earnings Tracker',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      routerConfig: router,
    );
  }
}
