import 'package:flutter_test/flutter_test.dart';
import 'package:foxsecura_mobile/security.dart';

void main() {
  test('rejects unsupported URL schemes', () {
    expect(UrlInspector.inspect('javascript:alert(1)').hasWarning, isTrue);
  });
  test('rejects relative URLs', () {
    expect(UrlInspector.inspect('example.com').url, isNull);
  });
  test('flags HTTP transport', () {
    expect(UrlInspector.inspect('http://example.com').hasWarning, isTrue);
  });
  test('flags punycode', () {
    expect(UrlInspector.inspect('https://xn--e1afmkfd.example').hasWarning, isTrue);
  });
  test('HTTPS result does not claim absolute safety', () {
    final result = UrlInspector.inspect('https://example.com');
    expect(result.hasWarning, isFalse);
    expect(result.findings.single.details, contains('ne garantit pas'));
  });
}
