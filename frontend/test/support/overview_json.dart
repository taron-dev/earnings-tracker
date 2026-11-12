/// Money as the backend writes it.
Map<String, dynamic> eurJson(String amount) => {'amount': amount, 'currency': 'EUR'};

Map<String, dynamic> itemJson(
  int position,
  String name,
  String target,
  String funded,
  String state, {
  required bool essential,
}) => {
  'position': position,
  'name': name,
  'target': eurJson(target),
  'funded': eurJson(funded),
  'state': state,
  'essential': essential,
};

/// A November plan 1480 EUR into funding: taxes covered, mortgage in progress, the rest open.
Map<String, dynamic> overviewJson({
  List<Map<String, dynamic>>? items,
  bool essentialsCovered = false,
  Map<String, dynamic>? nextMilestone = const {'position': 1, 'missing': {'amount': '170.00', 'currency': 'EUR'}, 'minutesNeeded': 255},
  String earnings = '1480.00',
  String unassigned = '0.00',
}) => {
  'planId': '6f1c2d4e-0000-4000-8000-000000000001',
  'window': {'from': '2026-11-01', 'to': '2026-11-30'},
  'earnings': eurJson(earnings),
  'essentialsCovered': essentialsCovered,
  'items':
      items ??
      [
        itemJson(0, 'Dane a odvody', '900.00', '900.00', 'COVERED', essential: true),
        itemJson(1, 'Hypotéka', '750.00', '580.00', 'IN_PROGRESS', essential: true),
        itemJson(2, 'Jedlo', '500.00', '0.00', 'UNCOVERED', essential: true),
        itemJson(3, 'Investovanie', '300.00', '0.00', 'UNCOVERED', essential: false),
        itemJson(4, 'Dovolenka', '200.00', '0.00', 'UNCOVERED', essential: false),
      ],
  'nextMilestone': nextMilestone,
  'unassignedEarnings': eurJson(unassigned),
};
