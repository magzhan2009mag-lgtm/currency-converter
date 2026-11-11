import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../models/exchange_rates.dart';
import '../utils/format.dart';

/// What one dollar, euro and rouble cost in tenge. Tapping a row puts that
/// pair into the converter.
class RatesTable extends StatelessWidget {
  const RatesTable({super.key, required this.rates, required this.onSelect});

  final ExchangeRates rates;
  final ValueChanged<Currency> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final others = Currency.values.where((c) => c != Currency.kzt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Курсы к тенге',
              style: theme.textTheme.titleSmall!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final currency in others)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              onTap: () => onSelect(currency),
              leading: CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                child: Text(
                  currency.symbol,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: Text(currency.title),
              subtitle: Text(currency.code),
              trailing: Text(
                '${formatRate(rates.rate(currency, Currency.kzt))} ₸',
                style: theme.textTheme.titleMedium!.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
