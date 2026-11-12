import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/today.dart';
import '../format/date_format.dart';
import '../money/money_format.dart';
import '../overview/plan_overview_api.dart';
import 'budget_item_dialog.dart';
import 'plan_draft.dart';
import 'plans_api.dart';
import 'plans_page.dart';

/// Creates a plan, prefilled as a copy of the plan that ends last, or edits plan [planId].
class PlanFormPage extends ConsumerWidget {
  const PlanFormPage({super.key, this.planId});

  /// The plan being edited; null when creating a new one.
  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = planId == null ? 'Nový plán' : 'Upraviť plán';
    return ref.watch(plansProvider).when(
          data: (plans) {
            if (planId == null) {
              return PlanForm(initial: PlanDraft.newPlan(plans), title: title);
            }
            final plan = plans.where((plan) => plan.planId == planId).firstOrNull;
            if (plan == null) {
              return Scaffold(
                appBar: AppBar(title: Text(title)),
                body: PlansMessage(
                  title: 'Plán neexistuje.',
                  action: TextButton(onPressed: () => context.go('/plans'), child: const Text('Na zoznam plánov')),
                ),
              );
            }
            return PlanForm(initial: PlanDraft.fromPlan(plan), planId: planId, title: title);
          },
          loading: () => Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: PlansMessage(
              title: 'Nepodarilo sa načítať plány. Skontroluj pripojenie.',
              action: TextButton(onPressed: () => ref.invalidate(plansProvider), child: const Text('Skúsiť znova')),
            ),
          ),
        );
  }
}

/// Window and items of a plan in one reorderable list, with the Essentials Line as a row of
/// its own that is dragged like the items.
class PlanForm extends ConsumerStatefulWidget {
  const PlanForm({super.key, required this.initial, this.planId, required this.title});

  final PlanDraft initial;
  final String? planId;
  final String title;

  @override
  ConsumerState<PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<PlanForm> {
  late PlanDraft _draft = widget.initial;
  bool _saving = false;
  String? _windowError;
  String? _error;

  bool get _changed => !_draft.sameAs(widget.initial);

  Future<void> _pickWindow() async {
    final today = ref.read(todayProvider);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _draft.hasWindow ? DateTimeRange(start: _draft.windowFrom!, end: _draft.windowTo!) : null,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.withWindow(picked.start, picked.end);
      _windowError = null;
    });
  }

  Future<void> _editItem(int? index) async {
    final result = await showBudgetItemDialog(context, existing: index == null ? null : _draft.items[index]);
    if (result == null) return;
    setState(() {
      _draft = switch (result) {
        ItemSaved(:final item) => index == null ? _draft.addItem(item) : _draft.replaceItem(index, item),
        ItemRemoved() => _draft.removeItem(index!),
      };
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _windowError = null;
      _error = null;
    });
    try {
      final api = ref.read(plansApiProvider);
      final id = widget.planId ?? await api.create(_draft);
      if (widget.planId != null) await api.update(id, _draft);
      ref.invalidate(plansProvider);
      ref.invalidate(overviewProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.go('/plans/$id');
      messenger.showSnackBar(const SnackBar(content: Text('Plán uložený.')));
    } on OverlappingPlanException {
      // The form stays as typed, so only the window needs changing.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _windowError = 'Okno sa prekrýva s iným plánom.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Uloženie zlyhalo.';
      });
    }
  }

  /// Leaving with unsaved changes asks first; a plan of ten items is a lot to lose to a tap.
  Future<void> _confirmLeave() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zahodiť zmeny?'),
        content: const Text('Neuložené zmeny plánu sa stratia.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Pokračovať v úprave')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Zahodiť')),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _draft.rows;
    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            // A new plan has no window until the user picks one.
            TextButton(onPressed: _saving || !_draft.hasWindow ? null : _save, child: const Text('Uložiť')),
          ],
        ),
        body: ReorderableListView(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.only(bottom: 24),
          header: _header(context),
          footer: _footer(context),
          onReorderItem: (oldIndex, newIndex) => setState(() => _draft = _draft.moveRow(oldIndex, newIndex)),
          children: [
            for (var i = 0; i < rows.length; i++)
              switch (rows[i]) {
                ItemRow(:final index, :final item) => ListTile(
                    key: ObjectKey(item),
                    title: Text(item.name),
                    onTap: () => _editItem(index),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatMoney(item.target)),
                        const SizedBox(width: 8),
                        ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                      ],
                    ),
                  ),
                EssentialsLineRow() => _EssentialsLine(key: const Key('essentials-line'), index: i),
              },
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Okno zárabania', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('plan-window'),
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_draft.hasWindow ? formatWindow(_draft.windowFrom!, _draft.windowTo!) : 'Vyber okno'),
            onPressed: _pickWindow,
          ),
          if (_windowError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_windowError!, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 24),
          Text('Položky v poradí pokrývania', style: textTheme.labelLarge),
          Text('Ťahaním za ☰ meníš poradie aj hranicu základu.', style: textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(icon: const Icon(Icons.add), label: const Text('Pridať položku'), onPressed: () => _editItem(null)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }
}

/// The Essentials Line: items above it are Essentials, below it Extras.
class _EssentialsLine extends StatelessWidget {
  const _EssentialsLine({super.key, required this.index});

  /// Row index in the reorderable list.
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('▲ ZÁKLAD · EXTRA ▼', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
          ),
          Expanded(child: Divider(color: color, thickness: 2)),
          const SizedBox(width: 8),
          ReorderableDragStartListener(index: index, child: Icon(Icons.drag_handle, color: color)),
        ],
      ),
    );
  }
}
