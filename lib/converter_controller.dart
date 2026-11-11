import 'package:flutter/foundation.dart';

import 'data/rates_exception.dart';
import 'data/rates_repository.dart';
import 'data/selection_store.dart';
import 'models/currency.dart';
import 'models/exchange_rates.dart';
import 'utils/format.dart';

/// Screen state: the rates being shown, where they came from, the last
/// network error, and what the user picked. The screen rebuilds on
/// [notifyListeners].
class ConverterController extends ChangeNotifier {
  ConverterController({
    required RatesRepository repository,
    required SelectionStore selection,
    DateTime Function()? clock,
  }) : _repository = repository,
       _selection = selection,
       _clock = clock ?? DateTime.now,
       _from = selection.from,
       _to = selection.to,
       _amountText = selection.amount;

  /// Rates older than this are refreshed when the app comes back to the
  /// foreground. The API itself updates once a day.
  static const staleAfter = Duration(hours: 1);

  final RatesRepository _repository;
  final SelectionStore _selection;
  final DateTime Function() _clock;

  ExchangeRates? _rates;
  RatesSource? _source;
  RatesException? _error;
  bool _loading = false;
  Future<void>? _inFlight;

  Currency _from;
  Currency _to;
  String _amountText;

  // ---- Rates ---------------------------------------------------------------

  /// Null until the first rates arrive, from the cache or the network.
  ExchangeRates? get rates => _rates;
  RatesSource? get source => _source;

  /// The last download error. Null after a successful download.
  RatesException? get error => _error;
  bool get loading => _loading;

  /// Shows the saved rates right away, then goes to the network.
  Future<void> start() {
    _rates = _repository.cached;
    if (_rates != null) _source = RatesSource.cache;
    notifyListeners();
    return refresh();
  }

  /// Downloads fresh rates. A second call while one is running joins it
  /// instead of sending another request.
  Future<void> refresh() =>
      _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  Future<void> _refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _repository.load();
      _rates = result.rates;
      _source = result.source;
      _error = result.error;
    } on RatesException catch (e) {
      // Nothing saved and nothing downloaded: the screen shows the error.
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Whether returning to the app should trigger a download.
  bool get needsRefresh {
    final rates = _rates;
    if (rates == null || _error != null) return true;
    return _clock().difference(rates.fetchedAt) > staleAfter;
  }

  // ---- Conversion ----------------------------------------------------------

  Currency get from => _from;
  Currency get to => _to;
  String get amountText => _amountText;

  /// Null when the field is empty or not a number.
  double? get amount => parseAmount(_amountText);

  /// Null while there are no rates or no valid amount.
  double? get result {
    final rates = _rates;
    final amount = this.amount;
    if (rates == null || amount == null) return null;
    return rates.convert(amount, _from, _to);
  }

  void setAmount(String text) {
    if (text == _amountText) return;
    _amountText = text;
    _changed();
  }

  /// Picking the currency already on the other side swaps them.
  void setFrom(Currency currency) {
    if (currency == _from) return;
    if (currency == _to) _to = _from;
    _from = currency;
    _changed();
  }

  void setTo(Currency currency) {
    if (currency == _to) return;
    if (currency == _from) _from = _to;
    _to = currency;
    _changed();
  }

  void swap() {
    final from = _from;
    _from = _to;
    _to = from;
    _changed();
  }

  void setPair(Currency from, Currency to) {
    if (from == to || (from == _from && to == _to)) return;
    _from = from;
    _to = to;
    _changed();
  }

  void _changed() {
    notifyListeners();
    _selection.save(from: _from, to: _to, amount: _amountText);
  }

  // ---- Lifecycle -----------------------------------------------------------

  bool _disposed = false;

  /// A download may finish after the screen is gone; don't notify then.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _repository.close();
    super.dispose();
  }
}
