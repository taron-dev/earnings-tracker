import 'package:earnings_tracker/money/money_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseEurInput', () {
    for (final (input, amount) in [('40', '40.00'), ('40,5', '40.50'), ('40.50', '40.50'), (' 0,30 ', '0.30')]) {
      test('reads "$input" as $amount EUR', () {
        expect(parseEurInput(input)?.toJson(), {'amount': amount, 'currency': 'EUR'});
      });
    }

    for (final input in ['', '   ', '0', '0,00', 'abc', '-5', '40,555', '4,0,0', ',5', '5,', '1 000']) {
      test('rejects "$input"', () {
        expect(parseEurInput(input), isNull);
      });
    }
  });
}
