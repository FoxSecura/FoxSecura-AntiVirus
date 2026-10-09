// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

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
  test('flags HTTPS URL with HTTP port 80', () {
    expect(UrlInspector.inspect('https://example.com:80').hasWarning, isTrue);
  });
  test('flags HTTP URL with HTTPS port 443', () {
    expect(UrlInspector.inspect('http://example.com:443').hasWarning, isTrue);
  });
  test('does not flag the matching HTTPS default port', () {
    expect(UrlInspector.inspect('https://example.com:443').hasWarning, isFalse);
  });
  test('does not flag the matching HTTP default port as nonstandard', () {
    final result = UrlInspector.inspect('http://example.com:80');
    expect(result.findings.any((f) => f.title == 'Port non standard'), isFalse);
  });
  test('HTTPS result does not claim absolute safety', () {
    final result = UrlInspector.inspect('https://example.com');
    expect(result.hasWarning, isFalse);
    expect(result.findings.single.details, contains('ne garantit pas'));
  });
}
