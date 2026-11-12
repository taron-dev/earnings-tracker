import 'package:earnings_tracker/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.fromJson', () {
    test('parses the amount string into minor units of the currency', () {
      final money = Money.fromJson({'amount': '123.45', 'currency': 'EUR'});

      expect(money.minorUnits, 12345);
      expect(money.scale, 2);
      expect(money.currency, 'EUR');
    });

    test('takes the scale from the amount string', () {
      final noDecimals = Money.fromJson({'amount': '260', 'currency': 'JPY'});
      final threeDecimals = Money.fromJson({'amount': '1.500', 'currency': 'KWD'});

      expect((noDecimals.minorUnits, noDecimals.scale), (260, 0));
      expect((threeDecimals.minorUnits, threeDecimals.scale), (1500, 3));
    });

    for (final invalid in ['-5.00', 'abc', '1,5', '1.2.3', '', '.5', '5.']) {
      test('rejects amount "$invalid"', () {
        expect(() => Money.fromJson({'amount': invalid, 'currency': 'EUR'}), throwsFormatException);
      });
    }
  });

  group('Money.toJson', () {
    for (final amount in ['123.45', '0.05', '40.00', '260', '1.500']) {
      test('writes back amount "$amount" unchanged', () {
        final json = {'amount': amount, 'currency': 'EUR'};

        expect(Money.fromJson(json).toJson(), json);
      });
    }
  });
}
