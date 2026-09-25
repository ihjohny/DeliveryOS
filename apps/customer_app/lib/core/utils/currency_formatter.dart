/// Unified currency formatting utility for DeliveryOS.
/// Default currency is Bangladeshi Taka (৳ / BDT), with support for multi-currency (e.g. SAR, USD).
class CurrencyFormatter {
  static const String defaultSymbol = '৳';

  /// Formats an amount with currency symbol.
  /// If [decimals] is 0 (default for BDT in DeliveryOS), rounds to nearest integer.
  static String format(num amount, {String symbol = defaultSymbol, int decimals = 0}) {
    if (decimals == 0) {
      return '$symbol${amount.round()}';
    }
    return '$symbol${amount.toStringAsFixed(decimals)}';
  }

  /// Formats amount with a unit suffix (e.g. "৳120 / kg" or "৳450 / portion").
  static String formatWithUnit(
    num amount,
    String unit, {
    String symbol = defaultSymbol,
    int decimals = 0,
  }) {
    final formatted = format(amount, symbol: symbol, decimals: decimals);
    return '$formatted / $unit';
  }

  /// Formats a discount / deduction (e.g. "-৳50").
  static String formatDiscount(num discountAmount, {String symbol = defaultSymbol, int decimals = 0}) {
    final formatted = format(discountAmount, symbol: symbol, decimals: decimals);
    return '-$formatted';
  }
}
