import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:project_3/converter_controller.dart';
import 'package:project_3/data/rates_api.dart';
import 'package:project_3/data/rates_cache.dart';
import 'package:project_3/data/rates_exception.dart';
import 'package:project_3/data/rates_repository.dart';
import 'package:project_3/data/selection_store.dart';
import 'package:project_3/models/currency.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late FakeServer server;
  late SharedPreferences prefs;
  var now = DateTime(2026, 11, 11, 12);

  Future<ConverterController> controllerWith({
    Map<String, Object> saved = const {},
  }) async {
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    return ConverterController(
      repository: RatesRepository(
        api: RatesApi(client: server.client),
        cache: RatesCache(prefs),
      ),
      selection: SelectionStore(prefs),
      clock: () => now,
    );
  }

  Future<void> saveRates({double kzt = 440}) =>
      RatesCache(prefs).save(snapshot(kzt: kzt));

  setUp(() => server = FakeServer());

  group('loading rates', () {
    test(
      'shows saved rates at once, then replaces them with fresh ones',
      () async {
        final controller = await controllerWith();
        await saveRates(kzt: 440);
        final response = Completer<http.Response>();
        server.handler = (_) => response.future;

        final started = controller.start();
        expect(rateOf(controller.rates!, Currency.kzt), 440);
        expect(controller.source, RatesSource.cache);
        expect(controller.loading, isTrue);

        response.complete(http.Response(apiBody(), 200));
        await started;
        expect(rateOf(controller.rates!, Currency.kzt), 450);
        expect(controller.source, RatesSource.network);
        expect(controller.loading, isFalse);
        expect(controller.error, isNull);
      },
    );

    test(
      'offline with saved rates: keeps converting, reports the error',
      () async {
        final controller = await controllerWith();
        await saveRates(kzt: 440);
        server.handler = FakeServer.offline;

        await controller.start();

        expect(rateOf(controller.rates!, Currency.kzt), 440);
        expect(controller.source, RatesSource.cache);
        expect(controller.error, isA<NoConnectionException>());
        expect(controller.result, 44000); // 100 $ by default
      },
    );

    test('offline on first launch, then the network comes back', () async {
      final controller = await controllerWith();
      server.handler = FakeServer.offline;

      await controller.start();
      expect(controller.rates, isNull);
      expect(controller.error, isA<NoConnectionException>());
      expect(controller.result, isNull);

      server.handler = FakeServer.ok;
      await controller.refresh();
      expect(controller.rates, isNotNull);
      expect(controller.error, isNull);
      expect(controller.result, 45000);
    });

    test('back online clears the error', () async {
      final controller = await controllerWith();
      server.handler = FakeServer.offline;
      await saveRates();
      await controller.start();
      expect(controller.error, isNotNull);

      server.handler = FakeServer.ok;
      await controller.refresh();
      expect(controller.error, isNull);
      expect(controller.source, RatesSource.network);
    });

    test('parallel refreshes share one request', () async {
      final controller = await controllerWith();
      final response = Completer<http.Response>();
      server.handler = (_) => response.future;

      final a = controller.refresh();
      final b = controller.refresh();
      response.complete(http.Response(apiBody(), 200));
      await Future.wait([a, b]);

      expect(server.requests, 1);
    });

    test('needsRefresh', () async {
      final controller = await controllerWith();
      expect(controller.needsRefresh, isTrue); // nothing yet

      now = DateTime.now();
      await controller.refresh();
      expect(controller.needsRefresh, isFalse); // just downloaded

      now = now.add(const Duration(hours: 2));
      expect(controller.needsRefresh, isTrue); // stale

      server.handler = FakeServer.offline;
      now = DateTime.now();
      await controller.refresh();
      expect(controller.needsRefresh, isTrue); // last attempt failed
    });
  });

  group('converting', () {
    late ConverterController controller;

    setUp(() async {
      controller = await controllerWith();
      await controller.start();
    });

    test('defaults to 100 \$ → ₸', () {
      expect(controller.from, Currency.usd);
      expect(controller.to, Currency.kzt);
      expect(controller.result, 45000);
    });

    test('amount', () {
      controller.setAmount('2,5');
      expect(controller.result, 1125);
      controller.setAmount('');
      expect(controller.result, isNull);
    });

    test('picking the other side\'s currency swaps them', () {
      controller.setFrom(.kzt);
      expect((controller.from, controller.to), (Currency.kzt, Currency.usd));

      controller.setTo(.kzt);
      expect((controller.from, controller.to), (Currency.usd, Currency.kzt));
    });

    test('swap and setPair', () {
      controller.swap();
      expect((controller.from, controller.to), (Currency.kzt, Currency.usd));

      controller.setAmount('1000');
      controller.setPair(.rub, .kzt);
      expect(controller.result, 5000);
    });

    test('the choice is remembered', () async {
      controller.setPair(.eur, .rub);
      controller.setAmount('42');
      await pumpEventQueue();

      final store = SelectionStore(prefs);
      expect(
        (store.from, store.to, store.amount),
        (Currency.eur, Currency.rub, '42'),
      );
    });
  });
}
