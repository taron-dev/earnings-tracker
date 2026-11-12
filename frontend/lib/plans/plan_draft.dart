import '../api/iso_date.dart';
import '../money/money.dart';
import '../overview/plan_overview.dart';

/// A Budget Item as typed in the plan form.
class DraftItem {
  const DraftItem({required this.name, required this.target});

  final String name;
  final Money target;

  Map<String, dynamic> toJson() => {'name': name, 'target': target.toJson()};

  @override
  bool operator ==(Object other) =>
      other is DraftItem &&
      other.name == name &&
      other.target.minorUnits == target.minorUnits &&
      other.target.scale == target.scale &&
      other.target.currency == target.currency;

  @override
  int get hashCode => Object.hash(name, target.minorUnits, target.scale, target.currency);
}

/// One row of the plan form's reorderable list: an item or the Essentials Line.
sealed class PlanRow {
  const PlanRow();
}

class ItemRow extends PlanRow {
  const ItemRow(this.index, this.item);

  /// Position of [item] in the Funding Order.
  final int index;
  final DraftItem item;

  @override
  bool operator ==(Object other) => other is ItemRow && other.index == index && other.item == item;

  @override
  int get hashCode => Object.hash(index, item);
}

class EssentialsLineRow extends PlanRow {
  const EssentialsLineRow();

  @override
  bool operator ==(Object other) => other is EssentialsLineRow;

  @override
  int get hashCode => 0;
}

/// A plan being created or edited, before it is saved; every change returns a new draft.
class PlanDraft {
  const PlanDraft({this.windowFrom, this.windowTo, required this.items, required this.essentialsCount});

  /// A new plan with the items of the plan that ends last: names, amounts, order and the
  /// Essentials Line, but no window, which the user always picks. Empty without any plan.
  factory PlanDraft.newPlan(List<PlanOverview> plans) {
    if (plans.isEmpty) return const PlanDraft(items: [], essentialsCount: 0);
    final previous = plans.reduce((latest, plan) => plan.windowTo.isAfter(latest.windowTo) ? plan : latest);
    final copy = PlanDraft.fromPlan(previous);
    return PlanDraft(items: copy.items, essentialsCount: copy.essentialsCount);
  }

  /// The plan as it is, for editing.
  factory PlanDraft.fromPlan(PlanOverview plan) => PlanDraft(
    windowFrom: plan.windowFrom,
    windowTo: plan.windowTo,
    items: [for (final item in plan.items) DraftItem(name: item.name, target: item.target)],
    essentialsCount: plan.essentialsCount,
  );

  /// Earning Window, both days included; both null until the user picks one for a new plan.
  final DateTime? windowFrom;
  final DateTime? windowTo;

  bool get hasWindow => windowFrom != null && windowTo != null;

  /// In Funding Order.
  final List<DraftItem> items;

  /// How many items, from the start of the Funding Order, lie above the Essentials Line.
  final int essentialsCount;

  /// The items with the Essentials Line among them, as the form lists them.
  List<PlanRow> get rows => [
    for (var i = 0; i < items.length; i++) ...[
      if (i == essentialsCount) const EssentialsLineRow(),
      ItemRow(i, items[i]),
    ],
    if (essentialsCount == items.length) const EssentialsLineRow(),
  ];

  /// Moves the row at [oldIndex] so it ends up at [newIndex], counted after the move (the
  /// way `ReorderableListView.onReorderItem` reports it). Items keep their Funding Order
  /// relative to the line, so moving either an item or the line across shifts the boundary.
  PlanDraft moveRow(int oldIndex, int newIndex) {
    final reordered = rows;
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    return _fromRows(reordered);
  }

  /// Appends [item] at the end of the Funding Order, among the extras.
  PlanDraft addItem(DraftItem item) => _copy(items: [...items, item]);

  PlanDraft replaceItem(int index, DraftItem item) => _copy(items: [...items]..[index] = item);

  PlanDraft removeItem(int index) => _copy(
    items: [...items]..removeAt(index),
    essentialsCount: index < essentialsCount ? essentialsCount - 1 : essentialsCount,
  );

  PlanDraft withWindow(DateTime from, DateTime to) =>
      PlanDraft(windowFrom: from, windowTo: to, items: items, essentialsCount: essentialsCount);

  /// The body of `POST /api/plans` and `PUT /api/plans/{id}`; only with a window.
  Map<String, dynamic> toJson() {
    if (!hasWindow) throw StateError('A plan needs an earning window before it is saved');
    return {
      'window': {'from': isoDate(windowFrom!), 'to': isoDate(windowTo!)},
      'items': [for (final item in items) item.toJson()],
      'essentialsCount': essentialsCount,
    };
  }

  /// Whether saving this draft would store the same plan as [other].
  bool sameAs(PlanDraft other) =>
      windowFrom == other.windowFrom &&
      windowTo == other.windowTo &&
      essentialsCount == other.essentialsCount &&
      items.length == other.items.length &&
      [for (var i = 0; i < items.length; i++) items[i] == other.items[i]].every((same) => same);

  PlanDraft _copy({List<DraftItem>? items, int? essentialsCount}) => PlanDraft(
    windowFrom: windowFrom,
    windowTo: windowTo,
    items: items ?? this.items,
    essentialsCount: essentialsCount ?? this.essentialsCount,
  );

  PlanDraft _fromRows(List<PlanRow> rows) => _copy(
    items: [
      for (final row in rows)
        if (row is ItemRow) row.item,
    ],
    essentialsCount: rows.indexWhere((row) => row is EssentialsLineRow),
  );
}
