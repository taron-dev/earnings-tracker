import 'package:earnings_tracker/money/money.dart';
import 'package:earnings_tracker/money/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

Money eur(String amount) => Money.fromJson({'amount': amount, 'currency': 'EUR'});

/// Slovak formatting separates thousands and the currency sign with a no-break space.
const nbsp = ' ';

void main() {
  group('formatMoney', () {
    test('omits zero cents', () {
      expect(formatMoney(eur('750.00')), '750$nbsp€');
    });

    test('shows cents with a decimal comma when they are not zero', () {
      expect(formatMoney(eur('262.50')), '262,50$nbsp€');
      expect(formatMoney(eur('0.05')), '0,05$nbsp€');
    });

    test('separates thousands with a no-break space', () {
      expect(formatMoney(eur('1480.00')), '1${nbsp}480$nbsp€');
      expect(formatMoney(eur('12345.67')), '12${nbsp}345,67$nbsp€');
    });
  });

  group('formatAmount', () {
    test('formats like formatMoney without the currency sign', () {
      expect(formatAmount(eur('1200.00')), '1${nbsp}200');
      expect(formatAmount(eur('580.50')), '580,50');
    });
  });
}
