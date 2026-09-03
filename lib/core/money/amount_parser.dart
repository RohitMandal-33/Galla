String normalizeDevanagariDigits(String input) {
  const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  var result = input;
  for (var i = 0; i < devanagariDigits.length; i++) {
    result = result.replaceAll(devanagariDigits[i], '$i');
  }
  return result;
}

int parseAmountToMinor(String raw) {
  var cleaned = normalizeDevanagariDigits(
    raw,
  ).replaceAll(',', '').replaceAll(' ', '').trim().toLowerCase();

  // Strip common currency prefixes
  cleaned = cleaned.replaceAll(RegExp(r'^(rs\.?|npr|रु\.?|₹|\$)'), '');
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
