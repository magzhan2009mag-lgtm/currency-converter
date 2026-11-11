import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Russian number style: `1 234 567,89` (the space is non-breaking).
String formatMoney(double value) {
  // 0,004 $ would round to 0,00; show significant digits instead.
  if (value != 0 && value.abs() < 0.01) return formatRate(value);
  return _format(2).format(value);
}

/// Rates below one keep 4 significant digits: `1 ₸ = 0,002236 $`,
/// `1 ₽ = 5,39 ₸`.
String formatRate(double value) {
  if (value.abs() >= 1 || value == 0) return _format(2).format(value);
  final leadingZeros = (-math.log(value.abs()) / math.ln10).floor();
  return _format((leadingZeros + 4).clamp(2, 10)).format(value);
}

final _formats = <int, NumberFormat>{};

/// At least 2 decimals, at most [maxDigits].
NumberFormat _format(int maxDigits) =>
    _formats[maxDigits] ??= (NumberFormat.decimalPattern('ru')
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = maxDigits);

/// Parses what the user typed: `1000`, `1 000,5`, `1000.5`. Returns null for
/// an empty or unparsable field.
double? parseAmount(String text) {
  // \s also covers the non-breaking space that formatMoney puts in.
  final cleaned = text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  return value != null && value.isFinite && value >= 0 ? value : null;
}

const _months = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', //
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

/// `11 ноября, 05:02`, with the year added when it isn't the current one.
/// The day and month are joined by a non-breaking space so they never wrap
/// apart.
String formatDate(DateTime time, {DateTime? now}) {
  final local = time.toLocal();
  final year = local.year == (now ?? DateTime.now()).year
      ? ''
      : ' ${local.year}';
  return '${local.day}\u00a0${_months[local.month - 1]}$year, ${_hhmm(local)}';
}

/// `только что`, `25 мин назад`, `сегодня в 09:15`, `вчера в 18:40`, or a date.
String formatAgo(DateTime time, {DateTime? now}) {
  final current = (now ?? DateTime.now()).toLocal();
  final local = time.toLocal();
  final diff = current.difference(local);

  if (diff < const Duration(minutes: 1)) return 'только что';
  if (diff < const Duration(hours: 1)) return '${diff.inMinutes} мин назад';

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);
  // round(), not ~/: a day with a DST switch is 23 or 25 hours long.
  final daysAgo = (today.difference(day).inHours / 24).round();
  if (daysAgo == 0) return 'сегодня в ${_hhmm(local)}';
  if (daysAgo == 1) return 'вчера в ${_hhmm(local)}';
  return formatDate(local, now: current);
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
