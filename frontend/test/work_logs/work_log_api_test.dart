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

  test('records work on a day', () async {
    final adapter = FakeHttpAdapter((_) => (status: 201, body: workLogJson('n1', '2026-11-12', 390, '260.00')));

    final log = await WorkLogApi(fakeDio(adapter)).record(DateTime(2026, 11, 12), 390);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/api/work-logs');
    expect(request.data, {'day': '2026-11-12', 'minutes': 390});
    expect(log.id, 'n1');
    expect(log.earnings.toJson(), eurJson('260.00'));
  });

  test('changes the day and time of a work log', () async {
    final adapter = FakeHttpAdapter((_) => (status: 200, body: workLogJson('a1', '2026-11-10', 120, '80.00')));

    final log = await WorkLogApi(fakeDio(adapter)).update('a1', DateTime(2026, 11, 10), 120);

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/api/work-logs/a1');
    expect(request.data, {'day': '2026-11-10', 'minutes': 120});
    expect(log.minutes, 120);
  });

  test('deletes a work log', () async {
    final adapter = FakeHttpAdapter((_) => (status: 204, body: null));

    await WorkLogApi(fakeDio(adapter)).delete('a1');

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, '/api/work-logs/a1');
  });
}
