import 'package:earnings_tracker/format/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMinutes', () {
    for (final (minutes, text) in [(255, '4 h 15 min'), (45, '45 min'), (420, '7 h'), (1, '1 min')]) {
      test('$minutes minutes read "$text"', () {
        expect(formatMinutes(minutes), text);
      });
    }
  });
}
