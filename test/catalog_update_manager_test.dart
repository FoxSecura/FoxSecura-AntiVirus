// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foxsecura_mobile/catalog_update_manager.dart';
import 'package:foxsecura_mobile/catalog_transport.dart';

class MemoryCatalogStore implements CatalogStore {
  final values = <String, String>{};
  String? failKey;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == failKey) throw StateError('Simulated interrupted write');
    values[key] = value;
  }
}

List<int> manifest(int sequence) => utf8.encode(jsonEncode({
  'sequence': sequence,
  'version': 'test-$sequence',
  'entries': [{
    'id': 'EICAR-TEST-FILE',
    'sha256': '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f',
    'description': 'Test EICAR',
    'isTestOnly': true,
  }],
}));

void main() {
  test('offline restore of verified catalog after restart', () async {
    final pair = await Ed25519().newKeyPair();
    final key = (await pair.extractPublicKey()).bytes;
    final store = MemoryCatalogStore();
    final manager = CatalogUpdateManager(store: store, trustedPublicKey: key);
    final payload = manifest(2);
    final signature = await Ed25519().sign(payload, keyPair: pair);
    await manager.activate(payload: payload, signature: signature.bytes);

    final restarted = CatalogUpdateManager(store: store, trustedPublicKey: key);
    expect((await restarted.load())?.sequence, 2);
    expect((await restarted.load())?.version, 'test-2');
    expect(store.values[CatalogUpdateManager.sequenceKey], '2');
  });

  test('rejects repeated and older validly signed catalogs', () async {
    final pair = await Ed25519().newKeyPair();
    final store = MemoryCatalogStore();
    final manager = CatalogUpdateManager(
      store: store,
      trustedPublicKey: (await pair.extractPublicKey()).bytes,
    );
    final payload = manifest(4);
    final signature = await Ed25519().sign(payload, keyPair: pair);
    await manager.activate(payload: payload, signature: signature.bytes);
    await expectLater(
      manager.activate(payload: payload, signature: signature.bytes),
      throwsFormatException,
    );
    final older = manifest(3);
    await expectLater(
      manager.activate(payload: older,
        signature: (await Ed25519().sign(older, keyPair: pair)).bytes),
      throwsFormatException,
    );
  });

  test('rejects forged signatures and tampered cached data', () async {
    final pair = await Ed25519().newKeyPair();
    final impostor = await Ed25519().newKeyPair();
    final store = MemoryCatalogStore();
    final manager = CatalogUpdateManager(
      store: store,
      trustedPublicKey: (await pair.extractPublicKey()).bytes,
    );
    final payload = manifest(1);
    await expectLater(
      manager.activate(payload: payload,
        signature: (await Ed25519().sign(payload, keyPair: impostor)).bytes),
      throwsFormatException,
    );
    expect(await manager.load(), isNull);
    await manager.activate(payload: payload,
      signature: (await Ed25519().sign(payload, keyPair: pair)).bytes);
    store.values[CatalogUpdateManager.activeKey] = '{"payload":"invalid"}';
    expect(await manager.load(), isNull);
  });

  test('old cache, lost counter and interrupted write fail closed', () async {
    final pair = await Ed25519().newKeyPair();
    final store = MemoryCatalogStore();
    final manager = CatalogUpdateManager(
      store: store,
      trustedPublicKey: (await pair.extractPublicKey()).bytes,
    );
    final first = manifest(1);
    await manager.activate(payload: first,
      signature: (await Ed25519().sign(first, keyPair: pair)).bytes);
    final cachedOld = store.values[CatalogUpdateManager.activeKey];
    final second = manifest(2);
    await manager.activate(payload: second,
      signature: (await Ed25519().sign(second, keyPair: pair)).bytes);
    store.values[CatalogUpdateManager.activeKey] = cachedOld!;
    expect(await manager.load(), isNull);
    store.values.remove(CatalogUpdateManager.sequenceKey);
    expect(await manager.load(), isNull);
    await expectLater(
      manager.activate(payload: manifest(3),
        signature: (await Ed25519().sign(manifest(3), keyPair: pair)).bytes),
      throwsStateError,
    );
  });

  test('interrupted active-record write retains high-water mark', () async {
    final pair = await Ed25519().newKeyPair();
    final store = MemoryCatalogStore();
    final manager = CatalogUpdateManager(
      store: store,
      trustedPublicKey: (await pair.extractPublicKey()).bytes,
    );
    final first = manifest(1);
    await manager.activate(payload: first,
      signature: (await Ed25519().sign(first, keyPair: pair)).bytes);
    store.failKey = CatalogUpdateManager.activeKey;
    final second = manifest(2);
    await expectLater(
      manager.activate(payload: second,
        signature: (await Ed25519().sign(second, keyPair: pair)).bytes),
      throwsStateError,
    );
    expect(store.values[CatalogUpdateManager.sequenceKey], '2');
    expect(await manager.load(), isNull);
    store.failKey = null;
    final third = manifest(3);
    await manager.activate(payload: third,
      signature: (await Ed25519().sign(third, keyPair: pair)).bytes);
    expect((await manager.load())?.sequence, 3);
  });

  test('unconfigured binary does not activate anything', () async {
    final store = MemoryCatalogStore();
    final manager = CatalogUpdateManager(store: store, trustedPublicKey: null);
    expect(manager.isConfigured, isFalse);
    expect(await manager.load(), isNull);
    await expectLater(
      manager.activate(payload: manifest(1), signature: List.filled(64, 0)),
      throwsStateError,
    );
    expect(store.values, isEmpty);
  });

  test('transport refuses non-HTTPS or nonstandard origins', () {
    HttpsCatalogTransport.validateBase(
      Uri.parse('https://updates.example.org/signatures/'));
    for (final origin in [
      'http://updates.example.org/signatures/',
      'https://user:pass@updates.example.org/signatures/',
      'https://updates.example.org:8443/signatures/',
      'https://updates.example.org/signatures?private=token',
      'https://updates.example.org/signatures',
    ]) {
      expect(() => HttpsCatalogTransport.validateBase(Uri.parse(origin)),
        throwsFormatException);
    }
  });
}
