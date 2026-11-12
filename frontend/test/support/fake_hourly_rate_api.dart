import 'package:earnings_tracker/hourly_rate/hourly_rate_api.dart';
import 'package:earnings_tracker/money/hourly_rate.dart';
import 'package:earnings_tracker/money/money.dart';

HourlyRate eurPerHour(String amount) => HourlyRate(Money.fromJson({'amount': amount, 'currency': 'EUR'}));

/// In-memory stand-in for the backend hourly rate endpoint.
class FakeHourlyRateApi implements HourlyRateApi {
  FakeHourlyRateApi([this.rate]);

  HourlyRate? rate;
  bool failSaving = false;
  final List<HourlyRate> saved = [];

  @override
  Future<HourlyRate?> current() async => rate;

  @override
  Future<void> save(HourlyRate rate) async {
    if (failSaving) throw Exception('backend down');
    saved.add(rate);
    this.rate = rate;
  }
}
