import 'overview_json.dart';

/// A work log as the backend returns it.
Map<String, dynamic> workLogJson(String id, String day, int minutes, String earnings, {String rate = '40.00'}) => {
  'id': id,
  'day': day,
  'minutes': minutes,
  'hourlyRate': eurJson(rate),
  'earnings': eurJson(earnings),
};
