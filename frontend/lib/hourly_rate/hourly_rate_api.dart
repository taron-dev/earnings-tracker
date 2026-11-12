import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../money/hourly_rate.dart';
import '../money/money.dart';

/// `GET` / `PUT /api/hourly-rate`.
class HourlyRateApi {
  HourlyRateApi(this._dio);

  final Dio _dio;

  /// The current rate, or null when the user has not set one yet (404).
  Future<HourlyRate?> current() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/hourly-rate');
      return HourlyRate(Money.fromJson(response.data!['perHour'] as Map<String, dynamic>));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Replaces the current rate; applies only to work logged from now on.
  Future<void> save(HourlyRate rate) async {
    await _dio.put<void>('/api/hourly-rate', data: {'perHour': rate.perHour.toJson()});
  }
}

final hourlyRateApiProvider = Provider((ref) => HourlyRateApi(ref.watch(apiClientProvider)));

/// The user's current hourly rate, or null when not set; invalidate after saving a new one.
final hourlyRateProvider = FutureProvider<HourlyRate?>((ref) => ref.watch(hourlyRateApiProvider).current());
