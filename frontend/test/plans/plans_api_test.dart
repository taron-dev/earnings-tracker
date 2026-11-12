import 'package:dio/dio.dart';
import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:earnings_tracker/plans/plans_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http_adapter.dart';
import '../support/overview_json.dart';

void main() {
  test('reads all plans in the order the server sends them', () async {
    final october = overviewJson(
      planId: 'october',
      window: ('2026-10-01', '2026-10-31'),
      essentialsCount: 1,
      items: [itemJson(0, 'Dane a odvody', '900.00', '900.00', 'COVERED', essential: true)],
      essentialsCovered: true,
      nextMilestone: null,
      earnings: '1000.00',
      unassigned: '100.00',
    );
    final adapter = FakeHttpAdapter((_) => (status: 200, body: [overviewJson(nextMilestone: null), october]));

    final plans = await PlansApi(fakeDio(adapter)).list();

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/api/plans');
    expect(plans.map((plan) => plan.planId), [defaultPlanId, 'october']);
    final past = plans[1];
    expect(past.windowFrom, DateTime(2026, 10, 1));
    expect(past.windowTo, DateTime(2026, 10, 31));
    expect(past.essentialsCount, 1);
    expect(past.essentialsCovered, isTrue);
    expect(past.items.single.state, CoverageState.covered);
    expect(past.nextMilestone, isNull);
    expect(past.unassignedEarnings.toJson(), eurJson('100.00'));
  });

  test('reads no plans', () async {
    final adapter = FakeHttpAdapter((_) => (status: 200, body: <Object>[]));

    expect(await PlansApi(fakeDio(adapter)).list(), isEmpty);
  });

  test('lets failures through', () async {
    final adapter = FakeHttpAdapter((_) => (status: 500, body: null));

    await expectLater(PlansApi(fakeDio(adapter)).list(), throwsA(isA<DioException>()));
  });
}
