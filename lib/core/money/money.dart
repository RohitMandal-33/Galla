import 'package:intl/intl.dart';

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

  static int parseToMinor(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return 0;
    final lower = cleaned.toLowerCase();
    var multiplier = 1.0;
    var numberPart = lower;
    if (lower.endsWith('lakh') || lower.endsWith('lac')) {
      multiplier = 100000;
      numberPart = lower.replaceAll(RegExp(r'(lakh|lac)$'), '');
    } else if (lower.endsWith('k')) {
      multiplier = 1000;
      numberPart = lower.substring(0, lower.length - 1);
    }
    final value = double.tryParse(numberPart) ?? 0;
    return (value * multiplier * 100).round();
  }
}
