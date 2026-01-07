import 'package:intl/intl.dart';

/// Formats numeric prices into AED currency strings using the active locale.
class PriceFormatter {
  const PriceFormatter._();

  static String format(num value, {String currency = 'AED', String? locale}) {
    final effectiveLocale = locale ?? Intl.getCurrentLocale();
    final resolvedLocale = effectiveLocale.trim().isEmpty
        ? 'en'
        : effectiveLocale;
    final formatter = NumberFormat.currency(
      locale: resolvedLocale,
      symbol: '$currency ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }
}
