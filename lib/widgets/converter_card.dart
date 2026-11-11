import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../converter_controller.dart';
import '../utils/format.dart';
import 'currency_picker.dart';

/// Up to 12 digits, then one `.` or `,` and up to 2 decimals.
final _amountPattern = RegExp(r'^\d{0,12}([.,]\d{0,2})?$');

/// The amount field, the result and the rate between the chosen pair.
class ConverterCard extends StatelessWidget {
  const ConverterCard({
    super.key,
    required this.controller,
    required this.amountField,
  });

  final ConverterController controller;
  final TextEditingController amountField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rates = controller.rates!;
    final from = controller.from;
    final to = controller.to;
    final result = controller.result;
    final bigText = theme.textTheme.headlineLarge!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              label: 'Отдаю',
              picker: CurrencyPicker(
                selected: from,
                onChanged: controller.setFrom,
              ),
            ),
            TextField(
              key: const Key('amount'),
              controller: amountField,
              onChanged: controller.setAmount,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (old, updated) =>
                      _amountPattern.hasMatch(updated.text) ? updated : old,
                ),
              ],
              style: bigText,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                suffixText: from.symbol,
                suffixStyle: bigText.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            _SwapDivider(onSwap: controller.swap),
            _Header(
              label: 'Получаю',
              picker: CurrencyPicker(selected: to, onChanged: controller.setTo),
            ),
            const SizedBox(height: 8),
            // Same layout as the field above: number on the left, symbol on
            // the right. Long numbers shrink instead of overflowing.
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      result == null ? '0' : formatMoney(result),
                      key: const Key('result'),
                      style: bigText.copyWith(color: scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  to.symbol,
                  style: bigText.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '1 ${from.symbol} = ${formatRate(rates.rate(from, to))} ${to.symbol}',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label, required this.picker});

  final String label;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Label and picker share a line when there is room; on a narrow screen
    // or with large system fonts the picker moves under the label.
    // Full width, otherwise Wrap shrinks to its content and spaceBetween
    // has nothing to spread.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          picker,
        ],
      ),
    );
  }
}

class _SwapDivider extends StatelessWidget {
  const _SwapDivider({required this.onSwap});

  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton.filledTonal(
              onPressed: onSwap,
              tooltip: 'Поменять местами',
              icon: const Icon(Icons.swap_vert_rounded),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
