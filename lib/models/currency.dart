/// The four currencies the app converts between.
///
/// [code] is the ISO 4217 code the rates API uses as a key.
enum Currency {
  kzt('KZT', '₸', 'Казахстанский тенге'),
  usd('USD', r'$', 'Доллар США'),
  eur('EUR', '€', 'Евро'),
  rub('RUB', '₽', 'Российский рубль');

  const Currency(this.code, this.symbol, this.title);

  final String code;
  final String symbol;
  final String title;

  static Currency? fromCode(String? code) {
    for (final currency in values) {
      if (currency.code == code) return currency;
    }
    return null;
  }
}
