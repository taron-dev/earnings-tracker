import '../money/hourly_rate.dart';
import '../money/money.dart';

/// Time worked on a day, with the Hourly Rate that was current when it was recorded.
class WorkLog {
  const WorkLog({
    required this.id,
    required this.day,
    required this.minutes,
    required this.hourlyRate,
    required this.earnings,
  });

  final String id;
  final DateTime day;
  final int minutes;
  final HourlyRate hourlyRate;
  final Money earnings;

  factory WorkLog.fromJson(Map<String, dynamic> json) => WorkLog(
    id: json['id'] as String,
    day: DateTime.parse(json['day'] as String),
    minutes: json['minutes'] as int,
    hourlyRate: HourlyRate(Money.fromJson(json['hourlyRate'] as Map<String, dynamic>)),
    earnings: Money.fromJson(json['earnings'] as Map<String, dynamic>),
  );
}
