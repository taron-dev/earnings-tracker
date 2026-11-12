import 'package:flutter/material.dart';

import '../settings/settings_page.dart';

/// Work log tab; filled in by plan step 3.5.
class WorkLogsPage extends StatelessWidget {
  const WorkLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Záznamy práce'),
        actions: const [SettingsButton()],
      ),
    );
  }
}
