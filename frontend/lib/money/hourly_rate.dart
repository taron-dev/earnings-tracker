import 'money.dart';

/// Gross amount earned per worked hour, mirroring the backend `HourlyRate`.
class HourlyRate {
  const HourlyRate(this.perHour);

  final Money perHour;

  /// Earnings for [minutes] of work, in the currency and scale of [perHour], rounded half up
  /// like the backend. Adding half the divisor before integer division rounds half up for
  /// non-negative values.
  Money earningsFor(int minutes) => Money(
    minorUnits: (perHour.minorUnits * minutes + 30) ~/ 60,
    scale: perHour.scale,
    currency: perHour.currency,
  );
}
