import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/exchange_rates.dart';
import 'rates_exception.dart';

/// Downloads rates from ExchangeRate-API's free endpoint (no key needed,
/// updated once a day, allows requests from the browser).
///
/// Every failure is turned into a [RatesException], so callers deal with one
/// error type instead of socket, timeout, HTTP and JSON errors separately.
class RatesApi {
  RatesApi({http.Client? client, this.timeout = const Duration(seconds: 10)})
    : _client = client ?? http.Client();

  static final latestUrl = Uri.parse('https://open.er-api.com/v6/latest/USD');

  final http.Client _client;
  final Duration timeout;

  Future<ExchangeRates> fetchLatest() async {
    final http.Response response;
    try {
      response = await _client.get(latestUrl).timeout(timeout);
    } on TimeoutException {
      throw RequestTimeoutException(timeout);
    } on http.ClientException catch (e) {
      // No network, DNS failure, connection reset; on the web also CORS.
      throw NoConnectionException(e);
    } on Exception catch (e) {
      // E.g. a TLS handshake error behind a Wi-Fi login page: the request
      // didn't get through either.
      throw NoConnectionException(e);
    }

    if (response.statusCode != 200) {
      throw ServerException(response.statusCode);
    }

    final Object? json;
    try {
      // The API sends no charset, and http would fall back to Latin-1.
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw BadResponseException('body is not JSON: ${e.message}');
    }
    return parse(json, fetchedAt: DateTime.now());
  }

  /// Checks the shape of the response instead of trusting it: a missing field
  /// or a string where a number should be becomes [BadResponseException],
  /// not a crash somewhere in the UI.
  @visibleForTesting
  static ExchangeRates parse(Object? json, {required DateTime fetchedAt}) {
    switch (json) {
      case {
        'result': 'success',
        'time_last_update_unix': int updatedAt,
        'rates': Map<dynamic, dynamic> rawRates,
      }:
        final perUsd = parseRates(rawRates);
        if (perUsd == null) {
          throw const BadResponseException('a currency is missing or invalid');
        }
        return ExchangeRates(
          perUsd: perUsd,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000),
          fetchedAt: fetchedAt,
        );
      // The API reports its own errors with status 200 and this body.
      case {'result': 'error', 'error-type': String type}:
        throw BadResponseException('API error: $type');
      default:
        throw const BadResponseException('unexpected JSON shape');
    }
  }

  void close() => _client.close();
}
