import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../overview/plan_overview.dart';

/// `/api/plans`.
class PlansApi {
  PlansApi(this._dio);

  final Dio _dio;

  /// All plans with their coverage, newest window first, never with a next milestone.
  Future<List<PlanOverview>> list() async {
    final response = await _dio.get<List<dynamic>>('/api/plans');
    return [for (final plan in response.data!) PlanOverview.fromJson(plan as Map<String, dynamic>)];
  }
}

final plansApiProvider = Provider((ref) => PlansApi(ref.watch(apiClientProvider)));

/// All plans; invalidate after anything that changes a plan or Earnings.
final plansProvider = FutureProvider<List<PlanOverview>>((ref) => ref.watch(plansApiProvider).list());
