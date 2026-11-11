import 'package:flutter_test/flutter_test.dart';
import 'package:project_3/data/rates_api.dart';
import 'package:project_3/data/rates_cache.dart';
import 'package:project_3/data/rates_exception.dart';
import 'package:project_3/data/rates_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late FakeServer server;
  late RatesCache cache;
  late RatesRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = FakeServer();
    cache = RatesCache(await SharedPreferences.getInstance());
    repository = RatesRepository(
      api: RatesApi(client: server.client),
      cache: cache,
    );
  });

  test('online: returns fresh rates and caches them', () async {
    final result = await repository.load();

    expect(result.source, RatesSource.network);
    expect(result.error, isNull);
    expect(rateOf(result.rates, .kzt), 450);
    expect(rateOf(cache.load()!, .kzt), 450);
  });

  test('offline with saved rates: falls back to them', () async {
    await cache.save(snapshot(kzt: 440));
    server.handler = FakeServer.offline;

    final result = await repository.load();

    expect(result.source, RatesSource.cache);
    expect(result.error, isA<NoConnectionException>());
    expect(rateOf(result.rates, .kzt), 440);
  });

  test('offline with nothing saved: throws', () async {
    server.handler = FakeServer.offline;
    expect(repository.load(), throwsA(isA<NoConnectionException>()));
  });

  test('a failed download leaves the saved rates alone', () async {
    await cache.save(snapshot(kzt: 440));
    server.respond('garbage');

    final result = await repository.load();

    expect(result.error, isA<BadResponseException>());
    expect(rateOf(cache.load()!, .kzt), 440);
  });

  test('a successful download replaces the saved rates', () async {
    await cache.save(snapshot(kzt: 440));
    await repository.load();
    expect(rateOf(cache.load()!, .kzt), 450);
  });

  test('cached reads the device only', () async {
    expect(repository.cached, isNull);
    await cache.save(snapshot());
    expect(repository.cached, isNotNull);
    expect(server.requests, 0);
  });
}
