import 'package:flutter/material.dart';

import '../models/currency.dart';

/// `₸ | $ | € | ₽`: four segments, one always selected.
class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Currency selected;
  final ValueChanged<Currency> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Currency>(
      segments: [
        for (final currency in Currency.values)
          ButtonSegment(
            value: currency,
            label: Text(currency.symbol),
            tooltip: currency.title,
          ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.single),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }
}
