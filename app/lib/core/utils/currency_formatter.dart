import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactIndianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Converts integer paise to formatted Indian rupee string (e.g., ₹1,45.00 or ₹48.33).
  static String formatPaise(int paise, {bool showSign = false, bool compactIfWhole = false}) {
    final double rupees = paise / 100.0;
    final isNegative = paise < 0;
    final absRupees = rupees.abs();

    String formatted;
    if (compactIfWhole && (paise % 100 == 0)) {
      formatted = _compactIndianFormat.format(absRupees);
    } else {
      formatted = _indianFormat.format(absRupees);
    }

    if (isNegative) {
      return '-$formatted';
    } else if (showSign && paise > 0) {
      return '+$formatted';
    }
    return formatted;
  }

  /// Parses a user-entered rupee string or number into integer paise.
  /// E.g. "145" -> 14500, "145.50" -> 14550.
  static int parseRupeesToPaise(dynamic input) {
    if (input == null) return 0;
    if (input is int) return input * 100;
    if (input is double) return (input * 100).round();
    if (input is String) {
      final clean = input.replaceAll('₹', '').replaceAll(',', '').trim();
      final parsed = double.tryParse(clean);
      if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;
      return (parsed * 100).round();
    }
    return 0;
  }
}
