import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import 'hourly_rate_form.dart';
import 'theme_mode.dart';

/// Hourly rate and account.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(signedInEmailProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nastavenia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HourlyRateSection(),
          const Divider(height: 32),
          const ThemeModeSection(),
          const Divider(height: 32),
          if (email != null) Text('Prihlásený: $email'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Odhlásiť sa'),
              onPressed: () => ref.read(signOutProvider)(),
            ),
          ),
        ],
      ),
    );
  }
}

/// App bar action that opens [SettingsPage] on top of the current tab.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Nastavenia',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push('/settings'),
    );
  }
}

/// Light, dark or system theme.
class ThemeModeSection extends ConsumerWidget {
  const ThemeModeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vzhľad', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Svetlý')),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Tmavý')),
            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Systém')),
          ],
          selected: {ref.watch(themeModeProvider)},
          onSelectionChanged: (selected) => ref.read(themeModeProvider.notifier).choose(selected.single),
        ),
      ],
    );
  }
}
