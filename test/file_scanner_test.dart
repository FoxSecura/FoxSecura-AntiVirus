// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:io';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:foxsecura_mobile/signed_catalog_verifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foxsecura_mobile/file_scanner.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('foxsecura_test_'));
  tearDown(() async => dir.delete(recursive: true));

  test('detects the EICAR harmless test signature', () async {
    final path = File('${dir.path}/eicar.txt');
    await path.writeAsString(r'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*');
    final report = await FileScanner.scanLocalFile(path);
    expect(report.testSignatureFound, isTrue);
    expect(report.bytes, 68);
  });

  test('ordinary files never receive a safe verdict', () async {
    final path = File('${dir.path}/hello.txt');
    await path.writeAsString('hello');
    final report = await FileScanner.scanLocalFile(path);
    expect(report.testSignatureFound, isFalse);
    expect(report.sha256.length, 64);
  });

  test('scanner consumes a signature-verified catalog', () async {
    final file = File('${dir.path}/eicar-test.txt');
    await file.writeAsString(
      r'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*');
    final pair = await Ed25519().newKeyPair();
    final bytes = utf8.encode(jsonEncode({
      'sequence': 2,
      'version': 'signed-test',
      'entries': [{
        'id': 'EICAR-TEST-FILE',
        'sha256': FileScanner.eicarSha256,
        'description': 'EICAR harmless test',
        'isTestOnly': true,
      }]
    }));
    final signature = await Ed25519().sign(bytes, keyPair: pair);
    final catalog = await SignedCatalogVerifier(
      trustedPublicKey: (await pair.extractPublicKey()).bytes,
    ).verify(payload: bytes, signature: signature.bytes,
        minimumSequence: 1);
    final report = await FileScanner.scanLocalFile(file, catalogue: catalog);
    expect(report.signatureFound, isTrue);
    expect(report.testSignatureFound, isTrue);
    expect(report.catalogueVersion, 'signed-test');
  });

  test('rejects files above configured size limit', () async {
    final file = File('${dir.path}/oversized.dat');
    final handle = await file.open(mode: FileMode.write);
    try {
      await handle.truncate(FileScanner.maxBytes + 1);
    } finally {
      await handle.close();
    }
    await expectLater(
      FileScanner.scanLocalFile(file),
      throwsA(isA<StateError>()),
    );
  });
}
