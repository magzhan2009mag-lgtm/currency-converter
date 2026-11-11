import 'package:flutter_test/flutter_test.dart';
import 'package:project_3/utils/format.dart';

/// The non-breaking space Russian number formatting groups digits with.
const nb = '\u00a0';

void main() {
  group('formatMoney', () {
    test('groups thousands and keeps two decimals', () {
      expect(formatMoney(1234567.891), '1${nb}234${nb}567,89');
      expect(formatMoney(45000), '45${nb}000,00');
      expect(formatMoney(0), '0,00');
    });

    test('tiny amounts do not collapse to zero', () {
      expect(formatMoney(1 / 450), '0,002222');
    });
  });

  group('formatRate', () {
    test('rates above one get two decimals', () {
      expect(formatRate(447.273889), '447,27');
      expect(formatRate(5), '5,00');
    });

    test('rates below one keep four significant digits', () {
      expect(formatRate(1 / 447.273889), '0,002236');
      expect(formatRate(82.98451 / 447.273889), '0,1855');
      expect(formatRate(0.2), '0,20');
    });
  });

  group('parseAmount', () {
    test('accepts comma, dot and spaces', () {
      expect(parseAmount('1000'), 1000);
      expect(parseAmount('1 000,5'), 1000.5);
      expect(parseAmount('1${nb}000.5'), 1000.5);
      expect(parseAmount('5,'), 5);
      expect(parseAmount(',5'), 0.5);
    });

    test('returns null for nothing to convert', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount(' '), isNull);
      expect(parseAmount(','), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('-1'), isNull);
    });
  });

  group('dates', () {
    final now = DateTime(2026, 11, 11, 12, 0);

    test('formatDate adds the year only when it differs', () {
      expect(
        formatDate(DateTime(2026, 11, 11, 5, 2), now: now),
        '11\u00a0ноября, 05:02',
      );
      expect(
        formatDate(DateTime(2025, 1, 3, 9, 0), now: now),
        '3\u00a0января 2025, 09:00',
      );
    });

    test('formatAgo', () {
      String ago(Duration d) => formatAgo(now.subtract(d), now: now);

      expect(ago(const Duration(seconds: 30)), 'только что');
      expect(ago(const Duration(minutes: 25)), '25 мин назад');
      expect(ago(const Duration(hours: 2, minutes: 45)), 'сегодня в 09:15');
      expect(ago(const Duration(hours: 17, minutes: 20)), 'вчера в 18:40');
      expect(ago(const Duration(days: 3, hours: 2)), '8\u00a0ноября, 10:00');
    });
  });
}
