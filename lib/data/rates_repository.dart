import 'package:flutter/foundation.dart';

import '../models/exchange_rates.dart';
import 'rates_api.dart';
import 'rates_cache.dart';
import 'rates_exception.dart';

enum RatesSource { network, cache }

class RatesResult {
  const RatesResult(this.rates, this.source, [this.error]);

  final ExchangeRates rates;
  final RatesSource source;

  /// Why the network failed, when [source] is [RatesSource.cache].
  final RatesException? error;
}

/// The one place that decides where rates come from: network first, the
/// cache as a fallback. Widgets never call the API or the cache directly.
class RatesRepository {
  RatesRepository({required RatesApi api, required RatesCache cache})
    : _api = api,
      _cache = cache;

  final RatesApi _api;
  final RatesCache _cache;

  /// Rates saved on the device, read without touching the network.
  ExchangeRates? get cached => _cache.load();

  /// Tries to download fresh rates and saves them on success. If that fails,
  /// falls back to the saved ones and reports why in [RatesResult.error].
  /// Throws [RatesException] only when there is nothing saved either.
  Future<RatesResult> load() async {
    final ExchangeRates fresh;
    try {
      fresh = await _api.fetchLatest();
    } on RatesException catch (error) {
      debugPrint('Rates download failed: $error');
      final cached = _cache.load();
      if (cached == null) rethrow;
      return RatesResult(cached, RatesSource.cache, error);
    }

    try {
      await _cache.save(fresh);
    } on Exception catch (e) {
      // Not being able to save is no reason to hide rates we already have.
      debugPrint('Could not cache rates: $e');
    }
    return RatesResult(fresh, RatesSource.network);
  }

  void close() => _api.close();
}
