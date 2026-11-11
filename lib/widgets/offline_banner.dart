import 'package:flutter/material.dart';

import '../data/rates_exception.dart';
import '../utils/format.dart';
import 'error_icon.dart';

/// Shown above the converter when the download failed but saved rates are
/// still available: the app keeps working, the user knows the rates may be
/// out of date.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.error,
    required this.ratesDate,
    required this.loading,
    required this.onRetry,
  });

  final RatesException error;
  final DateTime ratesDate;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final background = light
        ? const Color(0xFFFFF1CC)
        : const Color(0xFF3A3014);
    final foreground = light
        ? const Color(0xFF4A3800)
        : const Color(0xFFFFE08A);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconFor(error), color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error.message,
                        style: theme.textTheme.titleSmall!.copyWith(
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Считаем по сохранённому курсу от ${formatDate(ratesDate)}.',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: loading ? null : onRetry,
                style: TextButton.styleFrom(foregroundColor: foreground),
                icon: loading
                    ? SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
