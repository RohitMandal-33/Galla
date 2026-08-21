import 'package:flutter_test/flutter_test.dart';
import 'package:galla/core/parser/nl_parser.dart';

void main() {
  test('parser is available', () {
    expect(NlParser().parse('sold 10').amountMinor, 1000);
  });
}
