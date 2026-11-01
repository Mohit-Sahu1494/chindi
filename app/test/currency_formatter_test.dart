import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter (Paise & Rupee Rules)', () {
    test('formats paise into Indian Rupee format correctly', () {
      expect(CurrencyFormatter.formatPaise(14500), '₹145.00');
      expect(CurrencyFormatter.formatPaise(4833), '₹48.33');
      expect(CurrencyFormatter.formatPaise(100), '₹1.00');
      expect(CurrencyFormatter.formatPaise(0), '₹0.00');
    });

    test('formats negative paise with minus sign', () {
      expect(CurrencyFormatter.formatPaise(-9000), '-₹90.00');
      expect(CurrencyFormatter.formatPaise(-14550), '-₹145.50');
    });

    test('formats positive paise with plus sign when showSign is true', () {
      expect(CurrencyFormatter.formatPaise(29000, showSign: true), '+₹290.00');
      expect(CurrencyFormatter.formatPaise(-29000, showSign: true), '-₹290.00');
    });

    test('formats Indian number grouping correctly for lakhs and thousands', () {
      // ₹1,50,000.00 = 15000000 paise
      expect(CurrencyFormatter.formatPaise(15000000), '₹1,50,000.00');
    });

    test('parses rupee inputs to integer paise without floating point inaccuracy', () {
      expect(CurrencyFormatter.parseRupeesToPaise('145'), 14500);
      expect(CurrencyFormatter.parseRupeesToPaise('48.33'), 4833);
      expect(CurrencyFormatter.parseRupeesToPaise('₹1,250.50'), 125050);
      expect(CurrencyFormatter.parseRupeesToPaise(145), 14500);
      expect(CurrencyFormatter.parseRupeesToPaise(48.33), 4833);
      expect(CurrencyFormatter.parseRupeesToPaise(''), 0);
      expect(CurrencyFormatter.parseRupeesToPaise('invalid'), 0);
    });
  });
}
