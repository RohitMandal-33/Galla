int parseAmountToMinor(String raw) {
  final cleaned = raw
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .trim()
      .toLowerCase();
  if (cleaned.isEmpty) return 0;
  var multiplier = 1.0;
  var numberPart = cleaned;
  if (cleaned.endsWith('lakh') || cleaned.endsWith('lac')) {
    multiplier = 100000;
    numberPart = cleaned.replaceAll(RegExp(r'(lakh|lac)$'), '');
  } else if (cleaned.endsWith('k')) {
    multiplier = 1000;
    numberPart = cleaned.substring(0, cleaned.length - 1);
  }
  final value = double.tryParse(numberPart) ?? 0;
  return (value * multiplier * 100).round();
}
