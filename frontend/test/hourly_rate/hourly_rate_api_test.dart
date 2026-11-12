import 'package:earnings_tracker/hourly_rate/hourly_rate_api.dart';
import 'package:earnings_tracker/money/hourly_rate.dart';
import 'package:earnings_tracker/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http_adapter.dart';

const eur40 = {'amount': '40.00', 'currency': 'EUR'};

void main() {
  test('reads the current hourly rate', () async {
    final adapter = FakeHttpAdapter((_) => (status: 200, body: {'perHour': eur40}));

    final rate = await HourlyRateApi(fakeDio(adapter)).current();

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/api/hourly-rate');
    expect(rate?.perHour.toJson(), eur40);
  });

  test('reads a missing hourly rate as null', () async {
    final adapter = FakeHttpAdapter((_) => (status: 404, body: null));

    expect(await HourlyRateApi(fakeDio(adapter)).current(), isNull);
  });

  test('saves the hourly rate', () async {
    final adapter = FakeHttpAdapter((_) => (status: 200, body: {'perHour': eur40}));

    await HourlyRateApi(fakeDio(adapter)).save(HourlyRate(Money.fromJson(eur40)));

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/api/hourly-rate');
    expect(request.data, {'perHour': eur40});
  });
}
