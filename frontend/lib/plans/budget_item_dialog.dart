import 'package:flutter/material.dart';

import '../money/money_format.dart';
import '../money/money_input.dart';
import 'plan_draft.dart';

/// What the user did in the item dialog; null from [showBudgetItemDialog] means cancelled.
sealed class BudgetItemDialogResult {
  const BudgetItemDialogResult();
}

class ItemSaved extends BudgetItemDialogResult {
  const ItemSaved(this.item);

  final DraftItem item;
}

class ItemRemoved extends BudgetItemDialogResult {
  const ItemRemoved();
}

/// Asks for a new Budget Item, or changes or removes [existing]. Nothing is stored until the
/// whole plan is saved, so removing needs no confirmation.
Future<BudgetItemDialogResult?> showBudgetItemDialog(BuildContext context, {DraftItem? existing}) =>
    showDialog<BudgetItemDialogResult>(context: context, builder: (context) => BudgetItemDialog(existing: existing));

class BudgetItemDialog extends StatefulWidget {
  const BudgetItemDialog({super.key, this.existing});

  final DraftItem? existing;

  @override
  State<BudgetItemDialog> createState() => _BudgetItemDialogState();
}

class _BudgetItemDialogState extends State<BudgetItemDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.existing == null ? '' : formatMoneyInput(widget.existing!.target),
  );

  /// The backend's limits: a name of at most 100 characters, an amount below 10 billion.
  static const _maxNameLength = 100;
  static const _maxMinorUnits = 999999999999;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// The item as typed, or null while the name is blank or the amount not a valid one.
  DraftItem? get _item {
    final name = _name.text.trim();
    final target = parseEurInput(_amount.text);
    if (name.isEmpty || name.length > _maxNameLength || target == null || target.minorUnits > _maxMinorUnits) {
      return null;
    }
    return DraftItem(name: name, target: target);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? 'Upraviť položku' : 'Nová položka'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('item-name'),
            controller: _name,
            autofocus: !editing,
            maxLength: _maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Názov', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('item-amount'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Suma', suffixText: '€', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        if (editing)
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Odstrániť'),
            onPressed: () => Navigator.of(context).pop(const ItemRemoved()),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Zrušiť')),
        FilledButton(
          onPressed: item == null ? null : () => Navigator.of(context).pop(ItemSaved(item)),
          child: Text(editing ? 'Uložiť' : 'Pridať'),
        ),
      ],
    );
  }
}
