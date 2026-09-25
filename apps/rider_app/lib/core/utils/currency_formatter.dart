String formatCurrency(num amount, {int decimalDigits = 0}) {
  return '৳${amount.toStringAsFixed(decimalDigits)}';
}
