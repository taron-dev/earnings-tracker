import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hourly_rate/hourly_rate_api.dart';
import '../money/hourly_rate.dart';
import '../money/money_format.dart';
import '../money/money_input.dart';
import '../overview/plan_overview_api.dart';

/// Loads the current hourly rate and lets the user change it.
class HourlyRateSection extends ConsumerWidget {
  const HourlyRateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(hourlyRateProvider).when(
          data: (rate) => HourlyRateForm(initial: rate),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nepodarilo sa načítať sadzbu. Skontroluj pripojenie.'),
              TextButton(onPressed: () => ref.invalidate(hourlyRateProvider), child: const Text('Skúsiť znova')),
            ],
          ),
        );
  }
}

class HourlyRateForm extends ConsumerStatefulWidget {
  const HourlyRateForm({super.key, required this.initial});

  final HourlyRate? initial;

  @override
  ConsumerState<HourlyRateForm> createState() => _HourlyRateFormState();
}

class _HourlyRateFormState extends ConsumerState<HourlyRateForm> {
  late final _controller = TextEditingController(
    text: widget.initial == null ? '' : formatMoneyInput(widget.initial!.perHour),
  );

  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(HourlyRate rate) async {
    setState(() {
      _saving = true;
      _message = null;
    });
    String message;
    try {
      await ref.read(hourlyRateApiProvider).save(rate);
      ref.invalidate(hourlyRateProvider);
      // The next milestone in hours depends on the rate, and a first rate replaces the 409 state.
      ref.invalidate(overviewProvider);
      message = 'Sadzba uložená.';
    } catch (_) {
      // The typed value stays in the field, so saving again is one tap.
      message = 'Uloženie zlyhalo.';
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final perHour = parseEurInput(_controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Hodinová sadzba',
            suffixText: '€ / h',
            helperText: 'Nová sadzba platí len pre práce zapísané odteraz.',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _message = null),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: perHour == null || _saving ? null : () => _save(HourlyRate(perHour)),
              child: const Text('Uložiť'),
            ),
            if (_message != null) ...[const SizedBox(width: 12), Expanded(child: Text(_message!))],
          ],
        ),
      ],
    );
  }
}
