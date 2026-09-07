import 'package:flutter_test/flutter_test.dart';
import 'package:galla/core/parser/nl_parser.dart';
import 'package:galla/core/utils/url_utils.dart';

void main() {
  test('parser is available', () {
    expect(NlParser().parse('sold 10').amountMinor, 1000);
  });

  test('galla web URL points to valid vercel domain', () {
    expect(kGallaWebUrl, 'https://gallaweb.vercel.app');
    expect(kGallaWebDomain, 'gallaweb.vercel.app');
    final uri = Uri.parse(kGallaWebUrl);
    expect(uri.isScheme('https'), isTrue);
    expect(uri.host, 'gallaweb.vercel.app');
  });
}
