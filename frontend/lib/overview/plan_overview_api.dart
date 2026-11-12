import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/iso_date.dart';
import '../app/today.dart';
import 'plan_overview.dart';

/// `GET /api/plans/current/overview?date=`.
class PlanOverviewApi {
  PlanOverviewApi(this._dio);

  final Dio _dio;

  /// Overview of the plan whose window contains [today], the user's local day.
  Future<OverviewResult> current(DateTime today) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/plans/current/overview',
        queryParameters: {'date': isoDate(today)},
      );
      return OverviewFound(PlanOverview.fromJson(response.data!));
    } on DioException catch (e) {
      // 409 on this endpoint means only `hourly-rate-not-set`.
      final status = e.response?.statusCode;
      if (status == 404) return const NoPlanForToday();
      if (status == 409) return const HourlyRateNotSet();
      rethrow;
    }
  }
}

final planOverviewApiProvider = Provider((ref) => PlanOverviewApi(ref.watch(apiClientProvider)));

/// Overview of today's plan; invalidate after anything that changes Earnings or the rate.
final overviewProvider = FutureProvider<OverviewResult>(
  (ref) => ref.watch(planOverviewApiProvider).current(ref.watch(todayProvider)),
);
