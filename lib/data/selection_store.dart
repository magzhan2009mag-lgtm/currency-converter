import 'package:shared_preferences/shared_preferences.dart';

import '../models/currency.dart';

/// Remembers the chosen currencies and the typed amount between launches.
class SelectionStore {
  SelectionStore(this._prefs);

  static const _fromKey = 'from';
  static const _toKey = 'to';
  static const _amountKey = 'amount';

  final SharedPreferences _prefs;

  Currency get from => Currency.fromCode(_prefs.getString(_fromKey)) ?? .usd;
  Currency get to => Currency.fromCode(_prefs.getString(_toKey)) ?? .kzt;
  String get amount => _prefs.getString(_amountKey) ?? '100';

  Future<void> save({
    required Currency from,
    required Currency to,
    required String amount,
  }) async {
    await _prefs.setString(_fromKey, from.code);
    await _prefs.setString(_toKey, to.code);
    await _prefs.setString(_amountKey, amount);
  }
}
