// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'package:flutter_test/flutter_test.dart';
import 'package:foxsecura_mobile/history_privacy.dart';
import 'package:foxsecura_mobile/signature_catalog.dart';

void main() {
  test('drops URL credentials, path, query and fragment', () {
    final value = HistoryPrivacy.urlHostOnly(
      'https://alice:password@example.com:8443/private?token=SECRET#fragment');
    expect(value, 'https://example.com:8443');
    expect(value, isNot(contains('SECRET')));
    expect(value, isNot(contains('password')));
  });

  test('invalid URL is not persisted raw', () {
    expect(HistoryPrivacy.urlHostOnly('my-secret-token'),
      'URL invalide (détails non conservés)');
  });

  test('file summary does not include a filename', () {
    expect(HistoryPrivacy.fileSummary(), isNot(contains('secret.pdf')));
  });

  test('catalogue validates and normalizes hashes', () {
    expect(SignatureCatalog.matchHash(SignatureCatalog.entries.single.sha256.toUpperCase())?.id,
      'EICAR-TEST-FILE');
    expect(SignatureCatalog.matchHash('bad-hash'), isNull);
    expect(SignatureCatalog.matchHash('0' * 64), isNull);
  });

  test('catalogue is explicitly test-only', () {
    expect(SignatureCatalog.entries.every((s) => s.isTestOnly), isTrue);
  });
}
