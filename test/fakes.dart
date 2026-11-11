import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_3/models/currency.dart';
import 'package:project_3/models/exchange_rates.dart';

/// 1 $ = 450 ₸ = 0,9 € = 90 ₽: round numbers that are easy to check by hand.
const testRates = {'USD': 1, 'EUR': 0.9, 'KZT': 450, 'RUB': 90};

/// 11 November 2026, 00:02:32 UTC.
const testUpdatedUnix = 1794355352;

/// A body shaped like the real open.er-api.com response.
String apiBody({
  Map<String, Object> rates = testRates,
  int updated = testUpdatedUnix,
}) => jsonEncode({
  'result': 'success',
  'provider': 'https://www.exchangerate-api.com',
  'time_last_update_unix': updated,
  'base_code': 'USD',
  'rates': {...rates, 'GBP': 0.77, 'JPY': 154.2},
});

ExchangeRates snapshot({
  double kzt = 450,
  DateTime? updatedAt,
  DateTime? fetchedAt,
}) => ExchangeRates(
  perUsd: {.usd: 1, .eur: 0.9, .kzt: kzt, .rub: 90},
  updatedAt: updatedAt ?? DateTime(2026, 11, 10, 5, 2),
  fetchedAt: fetchedAt ?? DateTime(2026, 11, 10, 18, 40),
);

/// A server whose behaviour a test can switch at any time, e.g. to go
/// offline and come back. Counts the requests it receives.
class FakeServer {
  Future<http.Response> Function(http.Request request) handler = ok;

  int requests = 0;

  late final http.Client client = MockClient((request) {
    requests++;
    return handler(request);
  });

  static Future<http.Response> ok(http.Request request) async =>
      http.Response(apiBody(), 200);

  static Future<http.Response> offline(http.Request request) async =>
      throw http.ClientException('Failed host lookup', request.url);

  void respond(String body, [int status = 200]) =>
      handler = (_) async => http.Response(body, status);
}

double rateOf(ExchangeRates rates, Currency currency) =>
    rates.perUsd[currency]!;
