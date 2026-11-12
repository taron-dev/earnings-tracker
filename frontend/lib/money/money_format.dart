import 'package:intl/intl.dart';

import 'money.dart';
import 'money_input.dart' show parseEurInput;

/// Formats [money] for Slovak users, omitting zero cents: `750 €`, `262,50 €`.
String formatMoney(Money money) =>
    _format(money, (decimalDigits) => NumberFormat.simpleCurrency(locale: 'sk', name: money.currency, decimalDigits: decimalDigits));

/// Like [formatMoney] without the currency sign, for `580 / 750 €`.
String formatAmount(Money money) =>
    _format(money, (decimalDigits) => NumberFormat.decimalPatternDigits(locale: 'sk', decimalDigits: decimalDigits));

String _format(Money money, NumberFormat Function(int decimalDigits) formatWith) {
  final divisor = _pow10(money.scale);
  final hasFraction = money.minorUnits % divisor != 0;
  final format = formatWith(hasFraction ? money.scale : 0);
  // Converting to double is only for display: printed with exactly `scale` digits, any
  // realistic amount comes back exact. All arithmetic stays in integer minor units.
  return hasFraction ? format.format(money.minorUnits / divisor) : format.format(money.minorUnits ~/ divisor);
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

/// Formats [money] for an input field: no currency sign or thousands separator, zero cents
/// omitted (`40`, `40,50`), so [parseEurInput] reads it back.
String formatMoneyInput(Money money) {
  final divisor = _pow10(money.scale);
  final whole = money.minorUnits ~/ divisor;
  final fraction = money.minorUnits % divisor;
  if (fraction == 0) return '$whole';
  return '$whole,${fraction.toString().padLeft(money.scale, '0')}';
}
