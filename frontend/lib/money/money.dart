/// An amount of money as sent by the API: `{"amount": "123.45", "currency": "EUR"}`.
///
/// Kept as integer minor units plus the number of decimal places ([scale]) read from the
/// amount string, so no precision is lost and no floating point is involved.
class Money {
  const Money({required this.minorUnits, required this.scale, required this.currency});

  final int minorUnits;
  final int scale;
  final String currency;

  /// Non-negative digits with an optional fraction, as the backend writes them.
  static final _amountPattern = RegExp(r'^(\d+)(?:\.(\d+))?$');

  factory Money.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] as String;
    final match = _amountPattern.firstMatch(amount);
    if (match == null) {
      throw FormatException('Invalid money amount', amount);
    }
    final fraction = match.group(2) ?? '';
    return Money(
      minorUnits: int.parse(match.group(1)! + fraction),
      scale: fraction.length,
      currency: json['currency'] as String,
    );
  }

  /// Sum of two amounts in the same currency and scale, as the backend sends them.
  Money plus(Money other) {
    if (other.currency != currency || other.scale != scale) {
      throw ArgumentError('Cannot add $other to $this');
    }
    return Money(minorUnits: minorUnits + other.minorUnits, scale: scale, currency: currency);
  }

  @override
  String toString() => '${_amountString()} $currency';

  Map<String, dynamic> toJson() => {'amount': _amountString(), 'currency': currency};

  String _amountString() {
    final digits = minorUnits.toString().padLeft(scale + 1, '0');
    if (scale == 0) return digits;
    final split = digits.length - scale;
    return '${digits.substring(0, split)}.${digits.substring(split)}';
  }
}
