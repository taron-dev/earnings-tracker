import 'package:flutter/material.dart';

import '../settings/settings_page.dart';

/// Plan overview tab; filled in by plan step 3.4.
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prehľad'),
        actions: const [SettingsButton()],
      ),
    );
  }
}
