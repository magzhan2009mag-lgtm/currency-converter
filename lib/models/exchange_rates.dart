import 'package:flutter/foundation.dart';

import 'currency.dart';

/// One snapshot of exchange rates, every rate relative to one US dollar.
///
/// The same class is built from the API response and from the cache, so the
/// rest of the app doesn't care where the numbers came from.
@immutable
class ExchangeRates {
  ExchangeRates({
    required Map<Currency, double> perUsd,
    required this.updatedAt,
    required this.fetchedAt,
  }) : perUsd = Map.unmodifiable(perUsd),
       assert(Currency.values.every(perUsd.containsKey));

  /// How many units of each currency one US dollar buys.
  final Map<Currency, double> perUsd;

  /// When the provider published these rates.
  final DateTime updatedAt;

  /// When this device downloaded them.
  final DateTime fetchedAt;

  /// How many [to] one unit of [from] costs.
  double rate(Currency from, Currency to) => perUsd[to]! / perUsd[from]!;

  double convert(double amount, Currency from, Currency to) =>
      amount * rate(from, to);

  Map<String, Object> toJson() => {
    'rates': {for (final e in perUsd.entries) e.key.code: e.value},
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'fetchedAt': fetchedAt.millisecondsSinceEpoch,
  };

  /// Returns null when [json] is not a complete snapshot, e.g. a damaged or
  /// outdated cache entry.
  static ExchangeRates? fromJson(Object? json) {
    if (json case {
      'rates': Map<dynamic, dynamic> rawRates,
      'updatedAt': int updatedAt,
      'fetchedAt': int fetchedAt,
    }) {
      final perUsd = parseRates(rawRates);
      if (perUsd == null) return null;
      return ExchangeRates(
        perUsd: perUsd,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetchedAt),
      );
    }
    return null;
  }
}

/// Picks our currencies out of a `{"KZT": 447.27, ...}` map. Returns null if
/// any of them is missing or is not a positive number.
Map<Currency, double>? parseRates(Map<dynamic, dynamic> raw) {
  final result = <Currency, double>{};
  for (final currency in Currency.values) {
    final value = raw[currency.code];
    if (value is! num || !value.isFinite || value <= 0) return null;
    result[currency] = value.toDouble();
  }
  return result;
}
