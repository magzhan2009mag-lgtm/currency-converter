import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_3/models/currency.dart';
import 'package:project_3/models/exchange_rates.dart';

import 'fakes.dart';

void main() {
  final rates = snapshot();

  test('cross rates go through the dollar', () {
    expect(rates.rate(.usd, .kzt), 450);
    expect(rates.rate(.eur, .kzt), closeTo(500, 1e-9));
    expect(rates.rate(.rub, .kzt), 5);
    expect(rates.rate(.kzt, .usd), closeTo(1 / 450, 1e-12));
  });

  test('convert', () {
    expect(rates.convert(100, .usd, .kzt), 45000);
    expect(rates.convert(1000, .kzt, .rub), 200);
    expect(rates.convert(50, .eur, .eur), 50);
  });

  test('survives a JSON round trip', () {
    final restored = ExchangeRates.fromJson(
      jsonDecode(jsonEncode(rates.toJson())),
    )!;
    expect(restored.perUsd, rates.perUsd);
    expect(restored.updatedAt, rates.updatedAt);
    expect(restored.fetchedAt, rates.fetchedAt);
  });

  test('fromJson rejects incomplete or malformed data', () {
    final good = rates.toJson();
    final rawRates = good['rates']! as Map<String, double>;

    expect(ExchangeRates.fromJson(null), isNull);
    expect(ExchangeRates.fromJson([1, 2]), isNull);
    expect(ExchangeRates.fromJson({...good, 'updatedAt': 'вчера'}), isNull);
    expect(
      ExchangeRates.fromJson({
        ...good,
        'rates': {...rawRates}..remove('KZT'),
      }),
      isNull,
    );
    expect(
      ExchangeRates.fromJson({
        ...good,
        'rates': {...rawRates, 'RUB': -1},
      }),
      isNull,
    );
  });

  test('Currency.fromCode', () {
    expect(Currency.fromCode('KZT'), Currency.kzt);
    expect(Currency.fromCode('GBP'), isNull);
    expect(Currency.fromCode(null), isNull);
  });
}
