import 'package:earnings_tracker/work_logs/work_log_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http_adapter.dart';
import '../support/overview_json.dart';
import '../support/work_log_json.dart';

void main() {
  test('lists work logs between two days', () async {
    final adapter = FakeHttpAdapter(
      (_) => (
        status: 200,
        body: [
          workLogJson('a1', '2026-11-12', 390, '260.00'),
          workLogJson('b2', '2026-11-11', 480, '320.00', rate: '40.00'),
        ],
      ),
    );

    final logs = await WorkLogApi(fakeDio(adapter)).list(DateTime(2026, 11, 1), DateTime(2026, 11, 30));

    final request = adapter.requests.single;
    expect(request.path, '/api/work-logs');
    expect(request.queryParameters, {'from': '2026-11-01', 'to': '2026-11-30'});

    expect(logs.map((log) => log.id), ['a1', 'b2']);
    final first = logs.first;
    expect(first.day, DateTime(2026, 11, 12));
    expect(first.minutes, 390);
    expect(first.hourlyRate.perHour.toJson(), eurJson('40.00'));
    expect(first.earnings.toJson(), eurJson('260.00'));
  });
}
