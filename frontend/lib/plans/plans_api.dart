import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../overview/plan_overview.dart';
import 'plan_draft.dart';

/// The Earning Window overlaps another plan's (409).
class OverlappingPlanException implements Exception {
  const OverlappingPlanException();
}

/// `/api/plans`.
class PlansApi {
  PlansApi(this._dio);

  final Dio _dio;

  /// All plans with their coverage, newest window first, never with a next milestone.
  Future<List<PlanOverview>> list() async {
    final response = await _dio.get<List<dynamic>>('/api/plans');
    return [for (final plan in response.data!) PlanOverview.fromJson(plan as Map<String, dynamic>)];
  }

  /// Stores [draft] as a new plan and returns its id.
  Future<String> create(PlanDraft draft) async {
    final response = await _overlapAware(() => _dio.post<Map<String, dynamic>>('/api/plans', data: draft.toJson()));
    return response.data!['id'] as String;
  }

  /// Replaces the whole plan [id] with [draft].
  Future<void> update(String id, PlanDraft draft) async {
    await _overlapAware(() => _dio.put<Map<String, dynamic>>('/api/plans/$id', data: draft.toJson()));
  }

  /// Work Logs from its window stay and fund whichever plan covers them later.
  Future<void> delete(String id) async {
    await _dio.delete<void>('/api/plans/$id');
  }

  /// A 409 when writing a plan means only an overlapping window.
  Future<T> _overlapAware<T>(Future<T> Function() write) async {
    try {
      return await write();
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) throw const OverlappingPlanException();
      rethrow;
    }
  }
}

final plansApiProvider = Provider((ref) => PlansApi(ref.watch(apiClientProvider)));

/// All plans; invalidate after anything that changes a plan or Earnings.
final plansProvider = FutureProvider<List<PlanOverview>>((ref) => ref.watch(plansApiProvider).list());
