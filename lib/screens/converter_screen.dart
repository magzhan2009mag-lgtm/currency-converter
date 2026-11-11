import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../converter_controller.dart';
import '../data/rates_exception.dart';
import '../data/rates_repository.dart';
import '../models/currency.dart';
import '../models/exchange_rates.dart';
import '../utils/format.dart';
import '../widgets/converter_card.dart';
import '../widgets/error_icon.dart';
import '../widgets/offline_banner.dart';
import '../widgets/rates_table.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, required this.controller});

  final ConverterController controller;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late final _amountField = TextEditingController(
    text: widget.controller.amountText,
  );
  late final AppLifecycleListener _lifecycle;
  late final Timer _clockTick;

  ConverterController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Coming back to the app after a while (or after being offline) is a
    // good moment to try the network again.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_controller.needsRefresh) _controller.refresh();
      },
    );
    // Keeps "загружен 5 мин назад" current.
    _clockTick = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _clockTick.cancel();
    _lifecycle.dispose();
    _amountField.dispose();
    super.dispose();
  }

  /// Pull-to-refresh and the app bar button. Failures already show up in the
  /// banner, so only success gets a snack bar.
  Future<void> _refreshByUser() async {
    await _controller.refresh();
    if (!mounted || _controller.error != null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Курс обновлён')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final rates = _controller.rates;
        final error = _controller.error;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Конвертер валют'),
            actions: [
              if (rates != null)
                _RefreshAction(
                  loading: _controller.loading,
                  onPressed: _refreshByUser,
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: rates != null
              ? _content(rates)
              : error != null
              ? _ErrorView(
                  error: error,
                  loading: _controller.loading,
                  onRetry: _controller.refresh,
                )
              : const _LoadingView(),
        );
      },
    );
  }

  Widget _content(ExchangeRates rates) {
    final error = _controller.error;
    return RefreshIndicator(
      onRefresh: _refreshByUser,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A phone-width column, centred on wide windows.
          final side = math.max(16.0, (constraints.maxWidth - 560) / 2);
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(side, 4, side, 32),
            children: [
              if (error != null) ...[
                OfflineBanner(
                  error: error,
                  ratesDate: rates.updatedAt,
                  loading: _controller.loading,
                  onRetry: _controller.refresh,
                ),
                const SizedBox(height: 12),
              ],
              ConverterCard(controller: _controller, amountField: _amountField),
              const SizedBox(height: 12),
              RatesTable(
                rates: rates,
                onSelect: (currency) =>
                    _controller.setPair(currency, Currency.kzt),
              ),
              const SizedBox(height: 16),
              _SourceNote(
                rates: rates,
                source: _controller.source,
                loading: _controller.loading,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RefreshAction extends StatelessWidget {
  const _RefreshAction({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Обновить курс',
      icon: const Icon(Icons.refresh_rounded),
    );
  }
}

/// Where the numbers come from and how old they are.
class _SourceNote extends StatelessWidget {
  const _SourceNote({
    required this.rates,
    required this.source,
    required this.loading,
  });

  final ExchangeRates rates;
  final RatesSource? source;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final fetched = switch (source) {
      RatesSource.network => 'Загружен ${formatAgo(rates.fetchedAt)}',
      _ when loading => 'Сохранённый курс, проверяем обновление…',
      _ => 'Сохранённый курс, загружен ${formatAgo(rates.fetchedAt)}',
    };
    return Text(
      'Курс от ${formatDate(rates.updatedAt)}\n'
      '$fetched\n'
      'Источник: ExchangeRate-API',
      key: const Key('source-note'),
      style: style.copyWith(height: 1.5),
      textAlign: TextAlign.center,
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загружаем курсы…'),
        ],
      ),
    );
  }
}

/// No saved rates and the download failed: nothing to convert with yet.
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.loading,
    required this.onRetry,
  });

  final RatesException error;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.onErrorContainer,
                child: Icon(iconFor(error), size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Не удалось загрузить курсы',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'После первой удачной загрузки курс сохранится, и конвертер '
                'будет работать без интернета.',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: loading ? null : onRetry,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
