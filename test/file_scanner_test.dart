// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:io';
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
