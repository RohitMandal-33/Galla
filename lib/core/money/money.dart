import 'package:intl/intl.dart';

import 'amount_parser.dart';

class Money {
  const Money(this.minor, {this.currency = 'NPR'});

  final int minor;
  final String currency;

  double get major => minor / 100.0;

  String get symbol => switch (currency) {
    'INR' => '₹',
    'USD' => '\$',
    'NPR' => 'Rs',
    _ => currency,
  };

  String format({bool withSymbol = true}) {
    final formatted = NumberFormat('#,##,##0.00').format(major);
    return withSymbol ? '$symbol $formatted' : formatted;
  }

  /// Compact form for dense UI (list rows, metrics): drops decimals when the
  /// amount is a whole number, keeps them otherwise.
  String formatCompact({bool withSymbol = true}) {
    final pattern = minor % 100 == 0 ? '#,##,##0' : '#,##,##0.##';
    final formatted = NumberFormat(pattern).format(major);
    return withSymbol ? '$symbol $formatted' : formatted;
  }

  /// Signed compact form: explicit +/− prefix so state never relies on color
  /// alone.
  String formatSigned({bool withSymbol = true}) {
    final sign = minor < 0 ? '−' : '+';
    return '$sign ${Money(minor.abs(), currency: currency).formatCompact(withSymbol: withSymbol)}';
  }

  static int parseToMinor(String raw) => parseAmountToMinor(raw);
}
