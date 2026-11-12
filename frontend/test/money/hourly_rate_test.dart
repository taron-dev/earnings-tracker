import 'package:earnings_tracker/money/hourly_rate.dart';
import 'package:earnings_tracker/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

Money eur(String amount) => Money.fromJson({'amount': amount, 'currency': 'EUR'});

void main() {
  group('HourlyRate.earningsFor', () {
    // Same cases as the backend HourlyRateTest, so the live preview matches what the server stores.
    test('earnings are rate times worked time', () {
      expect(HourlyRate(eur('30.00')).earningsFor(7 * 60 + 20).toJson(), eur('220.00').toJson());
    });

    test('earnings are rounded half up to cents', () {
      expect(HourlyRate(eur('25.00')).earningsFor(7).toJson(), eur('2.92').toJson());
      expect(HourlyRate(eur('0.30')).earningsFor(1).toJson(), eur('0.01').toJson());
    });
  });
}
