// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foxsecura_mobile/signed_catalog_verifier.dart';

void main() {
  test('accepts correctly signed catalogue and rejects alterations', () async {
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPair();
    final pub = await pair.extractPublicKey();
    final body = utf8.encode(jsonEncode({
      'sequence': 2,
      'version': 'test-2',
      'entries': [{
        'id': 'EICAR-TEST-FILE',
        'sha256': '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f',
        'description': 'Test EICAR',
        'isTestOnly': true,
      }]
    }));
    final sig = await algorithm.sign(body, keyPair: pair);
    final verifier = SignedCatalogVerifier(trustedPublicKey: pub.bytes);
    final verified = await verifier.verify(
      payload: body, signature: sig.bytes, minimumSequence: 1);
    expect(verified.sequence, 2);
    expect(verified.entries.single.id, 'EICAR-TEST-FILE');

    await expectLater(
      verifier.verify(payload: [...body, 32], signature: sig.bytes,
        minimumSequence: 1),
      throwsFormatException);
    await expectLater(
      verifier.verify(payload: body, signature: sig.bytes, minimumSequence: 2),
      throwsFormatException);
    await expectLater(
      SignedCatalogVerifier(trustedPublicKey: List.filled(32, 0)).verify(
        payload: body, signature: sig.bytes, minimumSequence: 1),
      throwsFormatException);
  });

  test('rejects oversized unsigned manifests before JSON parsing', () async {
    await expectLater(
      SignedCatalogVerifier(trustedPublicKey: List.filled(32, 0)).verify(
        payload: List.filled(SignedCatalogVerifier.maximumBytes + 1, 1),
        signature: List.filled(64, 0), minimumSequence: 0),
      throwsFormatException);
  });
}
