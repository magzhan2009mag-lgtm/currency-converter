import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:project_3/data/rates_api.dart';
import 'package:project_3/data/rates_exception.dart';
import 'package:project_3/models/currency.dart';

import 'fakes.dart';

void main() {
  late FakeServer server;
  late RatesApi api;

  setUp(() {
    server = FakeServer();
    api = RatesApi(client: server.client);
  });

  test('parses a successful response', () async {
    Uri? requested;
    server.handler = (request) {
      requested = request.url;
      return FakeServer.ok(request);
    };

    final before = DateTime.now();
    final rates = await api.fetchLatest();

    expect(requested, RatesApi.latestUrl);
    expect(rates.perUsd, {
      Currency.usd: 1.0,
      Currency.eur: 0.9,
      Currency.kzt: 450.0,
      Currency.rub: 90.0,
    });
    expect(
      rates.updatedAt,
      DateTime.fromMillisecondsSinceEpoch(testUpdatedUnix * 1000),
    );
    expect(rates.fetchedAt.isBefore(before), isFalse);
  });

  group('turns every failure into a RatesException', () {
    Future<RatesException> failure() async {
      try {
        await api.fetchLatest();
      } on RatesException catch (e) {
        return e;
      }
      fail('fetchLatest() should have thrown');
    }

    test('no connection', () async {
      server.handler = FakeServer.offline;
      expect(await failure(), isA<NoConnectionException>());
    });

    test('timeout', () async {
      api = RatesApi(
        client: server.client,
        timeout: const Duration(milliseconds: 50),
      );
      server.handler = (_) =>
          Completer<http.Response>().future; // never answers

      final error = await failure();
      expect(error, isA<RequestTimeoutException>());
    });

    test('HTTP error status', () async {
      server.respond('Internal Server Error', 500);
      final error = await failure();
      expect(error, isA<ServerException>());
      expect((error as ServerException).statusCode, 500);
      expect(error.message, contains('500'));

      server.respond('', 429);
      expect((await failure()).message, contains('Слишком много запросов'));
    });

    test('body is not JSON', () async {
      server.respond('<html>Wi-Fi login</html>');
      expect(await failure(), isA<BadResponseException>());
    });

    test('API reports an error with status 200', () async {
      server.respond('{"result":"error","error-type":"unsupported-code"}');
      final error = await failure();
      expect(error, isA<BadResponseException>());
      expect(error.toString(), contains('unsupported-code'));
    });

    test('a currency is missing', () async {
      server.respond(apiBody(rates: {'USD': 1, 'EUR': 0.9, 'RUB': 90}));
      expect(await failure(), isA<BadResponseException>());
    });

    test('a rate is not a number', () async {
      server.respond(apiBody(rates: {...testRates, 'KZT': '450'}));
      expect(await failure(), isA<BadResponseException>());
    });

    test('a field has the wrong type', () async {
      server.respond('{"result":"success","time_last_update_unix":"today"}');
      expect(await failure(), isA<BadResponseException>());
    });
  });
}
