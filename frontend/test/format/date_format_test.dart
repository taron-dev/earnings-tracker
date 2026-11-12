import 'package:earnings_tracker/format/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int year, int month, int day) => DateTime(year, month, day);

void main() {
  group('formatWindow', () {
    test('within one month', () {
      expect(formatWindow(d(2026, 11, 1), d(2026, 11, 30)), '1. – 30. 11. 2026');
    });

    test('across two months', () {
      expect(formatWindow(d(2026, 11, 15), d(2026, 12, 14)), '15. 11. – 14. 12. 2026');
    });

    test('across two years', () {
      expect(formatWindow(d(2026, 12, 15), d(2027, 1, 14)), '15. 12. 2026 – 14. 1. 2027');
    });
  });

  group('daysLeftLabel counts today', () {
    final windowEnd = d(2026, 11, 30);

    for (final (today, label) in [
      (d(2026, 11, 12), 'ešte 19 dní'),
      (d(2026, 11, 26), 'ešte 5 dní'),
      (d(2026, 11, 27), 'ešte 4 dni'),
      (d(2026, 11, 29), 'ešte 2 dni'),
      (d(2026, 11, 30), 'posledný deň'),
    ]) {
      test('on ${today.day}. 11. reads "$label"', () {
        expect(daysLeftLabel(windowEnd, today), label);
      });
    }

    test('ignores daylight saving changes', () {
      // Slovakia moves clocks back on 25 October 2026; local midnights are then 25 h apart.
      expect(daysLeftLabel(d(2026, 10, 31), d(2026, 10, 20)), 'ešte 12 dní');
    });
  });

  group('formatDay', () {
    test('shows the Slovak weekday abbreviation', () {
      expect(formatDay(d(2026, 11, 12)), 'št 12. 11.');
      expect(formatDay(d(2026, 11, 9)), 'po 9. 11.');
      expect(formatDay(d(2026, 11, 15)), 'ne 15. 11.');
    });
  });
}
