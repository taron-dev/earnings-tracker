import 'package:dio/dio.dart';
import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:earnings_tracker/overview/plan_overview_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http_adapter.dart';
import '../support/overview_json.dart';

void main() {
  final today = DateTime(2026, 11, 12);

  test('asks for the plan covering the local day', () async {
    final adapter = FakeHttpAdapter((_) => (status: 200, body: overviewJson()));

    await PlanOverviewApi(fakeDio(adapter)).current(today);

    expect(adapter.requests.single.path, '/api/plans/current/overview');
    expect(adapter.requests.single.queryParameters, {'date': '2026-11-12'});
  });

  test('reads the overview', () async {
    final adapter = FakeHttpAdapter((_) => (status: 200, body: overviewJson()));

    final result = await PlanOverviewApi(fakeDio(adapter)).current(today);

    final overview = (result as OverviewFound).overview;
    expect(overview.windowFrom, DateTime(2026, 11, 1));
    expect(overview.windowTo, DateTime(2026, 11, 30));
    expect(overview.earnings.toJson(), eurJson('1480.00'));
    expect(overview.essentialsCovered, isFalse);
    expect(overview.unassignedEarnings.toJson(), eurJson('0.00'));

    final mortgage = overview.items[1];
    expect(mortgage.position, 1);
    expect(mortgage.name, 'Hypotéka');
    expect(mortgage.target.toJson(), eurJson('750.00'));
    expect(mortgage.funded.toJson(), eurJson('580.00'));
    expect(mortgage.state, CoverageState.inProgress);
    expect(mortgage.essential, isTrue);
    expect(overview.items.map((item) => item.state), [
      CoverageState.covered,
      CoverageState.inProgress,
      CoverageState.uncovered,
      CoverageState.uncovered,
      CoverageState.uncovered,
    ]);

    final milestone = overview.nextMilestone!;
    expect(milestone.position, 1);
    expect(milestone.missing.toJson(), eurJson('170.00'));
    expect(milestone.minutesNeeded, 255);
  });

  test('reads a fully covered plan without a next milestone', () async {
    final adapter = FakeHttpAdapter((_) => (status: 200, body: overviewJson(nextMilestone: null)));

    final result = await PlanOverviewApi(fakeDio(adapter)).current(today);

    expect((result as OverviewFound).overview.nextMilestone, isNull);
  });

  test('reports a day outside every plan', () async {
    final adapter = FakeHttpAdapter((_) => (status: 404, body: {'status': 404}));

    expect(await PlanOverviewApi(fakeDio(adapter)).current(today), isA<NoPlanForToday>());
  });

  test('reports a missing hourly rate', () async {
    final adapter = FakeHttpAdapter((_) => (status: 409, body: {'type': 'hourly-rate-not-set', 'status': 409}));

    expect(await PlanOverviewApi(fakeDio(adapter)).current(today), isA<HourlyRateNotSet>());
  });

  test('lets other failures through', () async {
    final adapter = FakeHttpAdapter((_) => (status: 500, body: null));

    await expectLater(PlanOverviewApi(fakeDio(adapter)).current(today), throwsA(isA<DioException>()));
  });
}
