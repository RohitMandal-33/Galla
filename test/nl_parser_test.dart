import 'package:flutter_test/flutter_test.dart';
import 'package:galla/core/parser/nl_parser.dart';
import 'package:galla/domain/models.dart';

void main() {
  final parser = NlParser();

  test('parses a credit sale in English', () {
    final parsed = parser.parse('sold rice for 500 to Hari on credit');
    expect(parsed.confident, isTrue);
    expect(parsed.direction, Direction.moneyIn);
    expect(parsed.amountMinor, 50000);
    expect(parsed.isCredit, isTrue);
    expect(parsed.partyName, 'Hari');
  });

  test('parses an expense', () {
    final parsed = parser.parse('paid 1200 rent');
    expect(parsed.direction, Direction.moneyOut);
    expect(parsed.amountMinor, 120000);
    expect(parsed.category, 'Rent');
  });

  test('does not guess amount when none is present', () {
    final parsed = parser.parse('sold rice to Hari');
    expect(parsed.confident, isFalse);
    expect(parsed.amountMinor, isNull);
  });
}
