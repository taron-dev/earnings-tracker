import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The user's local calendar day; the backend has no time zone and trusts this date.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
