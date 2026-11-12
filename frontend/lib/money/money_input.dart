import 'money.dart';

/// Whole euros with an optional one- or two-digit fraction after a comma or a dot.
final _eurInputPattern = RegExp(r'^(\d+)(?:[.,](\d{1,2}))?$');

/// Reads a positive amount typed by the user (`40`, `40,5`, `40.50`) as euros, or null when it
/// is not one. The API accepts only EUR, which has two decimal places.
Money? parseEurInput(String input) {
  final match = _eurInputPattern.firstMatch(input.trim());
  if (match == null) return null;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final minorUnits = int.parse(match.group(1)! + fraction);
  if (minorUnits == 0) return null;
  return Money(minorUnits: minorUnits, scale: 2, currency: 'EUR');
}
