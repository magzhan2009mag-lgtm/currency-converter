import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'converter_controller.dart';
import 'screens/converter_screen.dart';

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({super.key, required this.controller});

  final ConverterController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Конвертер валют',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ConverterScreen(controller: controller),
    );
  }
}

ThemeData _theme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B6E69),
        brightness: brightness,
      ).copyWith(
        surface: light ? const Color(0xFFF2F5F4) : const Color(0xFF111615),
        surfaceContainerLow: light ? Colors.white : const Color(0xFF1A201F),
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
