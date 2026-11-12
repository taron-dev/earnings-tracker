import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';

/// Account settings; the hourly rate form joins in plan step 3.3.
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
