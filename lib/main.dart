import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'converter_controller.dart';
import 'data/rates_api.dart';
import 'data/rates_cache.dart';
import 'data/rates_repository.dart';
import 'data/selection_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final controller = ConverterController(
    repository: RatesRepository(api: RatesApi(), cache: RatesCache(prefs)),
    selection: SelectionStore(prefs),
  );
  runApp(CurrencyConverterApp(controller: controller));
  unawaited(controller.start());
}
