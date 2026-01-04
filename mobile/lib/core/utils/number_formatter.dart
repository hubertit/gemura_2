class NumberFormatter {
  /// Formats a number with comma separators for thousands
  /// Example: 2300 becomes "2,300"
  static String formatWithCommas(double number) {
    String numStr = number.toStringAsFixed(0);
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  /// Formats a number with comma separators and currency symbol
  /// Example: 2300 becomes "RWF 2,300"
  static String formatCurrency(double number, String currency) {
    return '$currency ${formatWithCommas(number)}';
  }

  /// Formats a number with comma separators and RWF currency
  /// Example: 2300 becomes "RWF 2,300"
  static String formatRWF(double number) {
    return formatCurrency(number, 'RWF');
  }
}
