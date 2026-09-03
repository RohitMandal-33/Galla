import 'package:flutter_test/flutter_test.dart';
import 'package:galla/core/money/amount_parser.dart';

void main() {
  group('AmountParser & Devanagari numerals', () {
    test('parses basic integer and decimal strings', () {
      expect(parseAmountToMinor('100'), 10000);
      expect(parseAmountToMinor('50.50'), 5050);
      expect(parseAmountToMinor('1,500'), 150000);
      expect(parseAmountToMinor('  250.75  '), 25075);
    });

    test('parses lakh and k suffixes', () {
      expect(parseAmountToMinor('1 lakh'), 10000000);
      expect(parseAmountToMinor('2.5 lac'), 25000000);
      expect(parseAmountToMinor('15k'), 1500000);
      expect(parseAmountToMinor('2.5k'), 250000);
    });

    test('normalizes Devanagari numerals to standard digits', () {
      expect(normalizeDevanagariDigits('०१२३४५६७८९'), '0123456789');
      expect(parseAmountToMinor('५००'), 50000);
      expect(parseAmountToMinor('१.५ lakh'), 15000000);
      expect(parseAmountToMinor('२५,०००'), 2500000);
    });

    test('handles currency prefixes smoothly', () {
      expect(parseAmountToMinor('Rs. 500'), 50000);
      expect(parseAmountToMinor('rs 1200'), 120000);
      expect(parseAmountToMinor('₹2500'), 250000);
      expect(parseAmountToMinor('\$50'), 5000);
      expect(parseAmountToMinor('रु ५००'), 50000);
      expect(parseAmountToMinor('NPR 1,000'), 100000);
    });

    test('gracefully handles empty and invalid inputs', () {
      expect(parseAmountToMinor(''), 0);
      expect(parseAmountToMinor('abc'), 0);
      expect(parseAmountToMinor('   '), 0);
    });
  });
}
