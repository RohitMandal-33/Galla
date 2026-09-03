import '../../core/money/amount_parser.dart';
import '../../domain/models.dart';

class NlParser {
  ParsedEntry parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const ParsedEntry();

    final lower = text.toLowerCase();
    final amountMinor = _extractAmount(lower);
    final isCredit = _looksLikeCredit(lower);
    final direction = _extractDirection(lower, isCredit);
    final party = _extractParty(text);
    final category = _extractCategory(lower);
    final confident = amountMinor != null && direction != null;

    return ParsedEntry(
      direction: direction,
      amountMinor: amountMinor,
      partyName: party,
      category: category,
      isCredit: isCredit,
      note: text,
      confident: confident,
    );
  }

  bool _looksLikeCredit(String lower) {
    const hints = [
      'udhaar',
      'udhar',
      'credit',
      'on credit',
      'baaki',
      'baki',
      'pachi',
      'later',
      'उधारो',
      'बाँकी',
    ];
    return hints.any(lower.contains);
  }

  Direction? _extractDirection(String lower, bool isCredit) {
    const inHints = [
      'sold',
      'sale',
      'income',
      'received',
      'got',
      'ayo',
      'aayo',
      'bech',
      'bechyo',
      'आयो',
      'बेच',
    ];
    const outHints = [
      'spent',
      'paid',
      'expense',
      'bought',
      'purchase',
      'kharcha',
      'kharche',
      'dine',
      'diye',
      'गयो',
      'खर्च',
      'किन',
    ];
    if (inHints.any(lower.contains)) return Direction.moneyIn;
    if (outHints.any(lower.contains)) return Direction.moneyOut;
    if (isCredit) return Direction.moneyIn;
    return null;
  }

  int? _extractAmount(String lower) {
    final lakh = RegExp(r'(\d+(?:[.,]\d+)?)\s*(lakh|lac)').firstMatch(lower);
    if (lakh != null) {
      return parseAmountToMinor('${lakh.group(1)} lakh');
    }
    final k = RegExp(r'(\d+(?:[.,]\d+)?)\s*k\b').firstMatch(lower);
    if (k != null) {
      return parseAmountToMinor('${k.group(1)} k');
    }
    final numbered = RegExp(
      r'(?:rs\.?|₹|\$)?\s*(\d{1,3}(?:,\d{2,3})+|\d+)(?:\.(\d{1,2}))?',
    ).allMatches(lower);
    int? best;
    for (final m in numbered) {
      final whole = m.group(1)!.replaceAll(',', '');
      final frac = m.group(2) ?? '0';
      final value = int.tryParse(whole);
      if (value == null) continue;
      final minor =
          value * 100 + int.parse(frac.padRight(2, '0').substring(0, 2));
      if (best == null || minor > best) best = minor;
    }
    return best;
  }

  String? _extractParty(String text) {
    final patterns = [
      RegExp(
        r'\bto\s+([A-Za-z\u0900-\u097F][A-Za-z\u0900-\u097F\s]{1,40})',
        caseSensitive: false,
      ),
      RegExp(
        r'\bfrom\s+([A-Za-z\u0900-\u097F][A-Za-z\u0900-\u097F\s]{1,40})',
        caseSensitive: false,
      ),
      RegExp(
        r'\blai\s+([A-Za-z\u0900-\u097F][A-Za-z\u0900-\u097F\s]{1,40})',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        return _cleanName(m.group(1)!);
      }
    }
    return null;
  }

  String _cleanName(String raw) {
    return raw
        .replaceAll(
          RegExp(
            r'\b(on credit|udhaar|udhar|baaki|baki|today|yesterday|rs|npr)\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  String? _extractCategory(String lower) {
    const map = {
      'rice': 'Groceries',
      'dal': 'Groceries',
      'oil': 'Groceries',
      'rent': 'Rent',
      'salary': 'Staff',
      'petrol': 'Transport',
      'diesel': 'Transport',
      'stock': 'Stock',
      'maal': 'Stock',
    };
    for (final e in map.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return null;
  }
}
