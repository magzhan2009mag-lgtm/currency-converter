import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exchange_rates.dart';

/// Keeps the last successfully downloaded rates on the device, so the app
/// still converts without internet. Stored as JSON in SharedPreferences:
/// a file on Android and Windows, localStorage in the browser.
class RatesCache {
  RatesCache(this._prefs);

  /// Bump the version if the JSON format changes: old entries are then
  /// simply ignored instead of being misread.
  static const key = 'rates_cache_v1';

  final SharedPreferences _prefs;

  ExchangeRates? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    ExchangeRates? rates;
    try {
      rates = ExchangeRates.fromJson(jsonDecode(raw));
    } on FormatException {
      rates = null;
    }
    // A damaged entry is dropped so it doesn't get in the way again.
    if (rates == null) _prefs.remove(key);
    return rates;
  }

  Future<void> save(ExchangeRates rates) =>
      _prefs.setString(key, jsonEncode(rates.toJson()));
}
