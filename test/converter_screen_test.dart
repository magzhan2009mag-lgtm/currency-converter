import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_3/app.dart';
import 'package:project_3/converter_controller.dart';
import 'package:project_3/data/rates_api.dart';
import 'package:project_3/data/rates_cache.dart';
import 'package:project_3/data/rates_repository.dart';
import 'package:project_3/data/selection_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

const nb = '\u00a0';

void main() {
  late FakeServer server;

  Future<void> launch(
    WidgetTester tester, {
    bool withSavedRates = false,
  }) async {
    // A typical phone screen, 411 × 914 logical pixels.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = RatesCache(prefs);
    if (withSavedRates) await cache.save(snapshot(kzt: 440));

    final controller = ConverterController(
      repository: RatesRepository(
        api: RatesApi(client: server.client),
        cache: cache,
      ),
      selection: SelectionStore(prefs),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(CurrencyConverterApp(controller: controller));
    await controller.start();
    await tester.pumpAndSettle();
  }

  setUp(() => server = FakeServer());

  testWidgets('online: converts as you type', (tester) async {
    await launch(tester);

    expect(find.text('45${nb}000,00'), findsOneWidget);
    expect(find.text('1 \$ = 450,00 ₸'), findsOneWidget);
    expect(find.textContaining('Загружен только что'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);

    await tester.enterText(find.byKey(const Key('amount')), '2,5');
    await tester.pump();
    expect(find.text('1${nb}125,00'), findsOneWidget);

    await tester.tap(find.byTooltip('Поменять местами'));
    await tester.pump();
    expect(find.text('0,005556'), findsOneWidget);
    expect(find.text('1 ₸ = 0,002222 \$'), findsOneWidget);
  });

  testWidgets('the rates table fills the converter', (tester) async {
    await launch(tester);

    expect(find.text('500,00 ₸'), findsOneWidget); // 1 € in the table
    await tester.tap(find.text('Евро'));
    await tester.pump();
    expect(find.text('50${nb}000,00'), findsOneWidget); // 100 €
  });

  testWidgets('offline with saved rates: banner, converter still works', (
    tester,
  ) async {
    server.handler = FakeServer.offline;
    await launch(tester, withSavedRates: true);

    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    expect(
      find.textContaining('сохранённому курсу от 10\u00a0ноября'),
      findsOneWidget,
    );
    expect(find.text('44${nb}000,00'), findsOneWidget);
    expect(find.textContaining('Сохранённый курс, загружен'), findsOneWidget);

    server.handler = FakeServer.ok;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Нет подключения к интернету'), findsNothing);
    expect(find.text('45${nb}000,00'), findsOneWidget);
  });

  testWidgets('offline on first launch: error screen with retry', (
    tester,
  ) async {
    server.handler = FakeServer.offline;
    await launch(tester);

    expect(find.text('Не удалось загрузить курсы'), findsOneWidget);
    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    expect(find.byKey(const Key('amount')), findsNothing);

    server.handler = FakeServer.ok;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить курсы'), findsNothing);
    expect(find.text('45${nb}000,00'), findsOneWidget);
  });

  testWidgets('bad server data is reported as such', (tester) async {
    server.respond('<html>502 Bad Gateway</html>');
    await launch(tester, withSavedRates: true);

    expect(find.text('Сервер прислал некорректные данные'), findsOneWidget);
  });

  testWidgets('manual refresh confirms success', (tester) async {
    await launch(tester);

    await tester.tap(find.byTooltip('Обновить курс'));
    await tester.pumpAndSettle();

    expect(find.text('Курс обновлён'), findsOneWidget);
    expect(server.requests, 2);
  });
}
