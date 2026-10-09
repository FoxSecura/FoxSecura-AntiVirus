// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'signed_catalog_verifier.dart';

/// Two independent application preference values. This is a best-effort
/// high-water mark, NOT a tamper-proof or hardware-backed monotonic counter.
abstract class CatalogStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PreferencesCatalogStore implements CatalogStore {
  const PreferencesCatalogStore();

  @override
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(key, value)) {
      throw StateError('Écriture du catalogue impossible');
    }
  }
}

class CatalogUpdateManager {
  CatalogUpdateManager({required this.store, required this.trustedPublicKey});

  final CatalogStore store;
  final List<int>? trustedPublicKey;
  static const String activeKey = 'foxsecura_signed_catalog_v1';
  static const String sequenceKey = 'foxsecura_signed_catalog_sequence_v1';

  bool get isConfigured =>
      trustedPublicKey != null && trustedPublicKey!.length == 32;

  Future<int> _minimumSequence() async {
    final raw = await store.read(sequenceKey);
    if (raw == null) {
      if (await store.read(activeKey) != null) {
        throw StateError('Compteur absent pour un catalogue installé');
      }
      return 0;
    }
    final value = int.tryParse(raw);
    if (value == null || value < 1) {
      throw StateError('Compteur de catalogue invalide');
    }
    return value;
  }

  /// Verify before activation. Persist the high-water mark FIRST: a crash
  /// between writes causes a fail-closed cache rather than accepting a
  /// previous signed version. Never install unsigned input.
  Future<VerifiedCatalog> activate({
    required List<int> payload,
    required List<int> signature,
  }) async {
    if (!isConfigured) {
      throw StateError('Clé publique FoxSecura non configurée');
    }
    final minimum = await _minimumSequence();
    final verified = await SignedCatalogVerifier(
      trustedPublicKey: trustedPublicKey!,
    ).verify(payload: payload, signature: signature, minimumSequence: minimum);
    final record = jsonEncode({
      'payload': base64Encode(payload),
      'signature': base64Encode(signature),
    });
    await store.write(sequenceKey, verified.sequence.toString());
    await store.write(activeKey, record);
    return verified;
  }

  /// Offline restore: reverify cached bytes and counter. Any inconsistency
  /// falls back to the bundled harmless EICAR demo, never to unsigned data.
  Future<VerifiedCatalog?> load() async {
    if (!isConfigured) return null;
    try {
      final record = await store.read(activeKey);
      if (record == null || record.length > 190000) return null;
      final floorRaw = await store.read(sequenceKey);
      final floor = floorRaw == null ? null : int.tryParse(floorRaw);
      if (floor == null || floor < 1) return null;

      final parsed = jsonDecode(record);
      if (parsed is! Map<String, dynamic> ||
          parsed['payload'] is! String || parsed['signature'] is! String) {
        return null;
      }
      final bytes = base64Decode(parsed['payload'] as String);
      final sig = base64Decode(parsed['signature'] as String);
      final verified = await SignedCatalogVerifier(
        trustedPublicKey: trustedPublicKey!,
      ).verify(payload: bytes, signature: sig, minimumSequence: 0);
      return verified.sequence == floor ? verified : null;
    } on Object {
      return null;
    }
  }
}

/// Only a build-time PINNED key can activate signed manifests.
/// No publisher key is shipped with this repository.
class CatalogTrustConfig {
  static const String publicKeyHex = String.fromEnvironment(
    'FOXSECURA_CATALOG_ED25519_PUBLIC_KEY_HEX',
  );
  static const String updateBaseUrl = String.fromEnvironment(
    'FOXSECURA_CATALOG_UPDATE_BASE_URL',
  );

  static List<int>? pinnedPublicKey() {
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(publicKeyHex)) return null;
    return List<int>.unmodifiable([
      for (var i = 0; i < publicKeyHex.length; i += 2)
        int.parse(publicKeyHex.substring(i, i + 2), radix: 16),
    ]);
  }
}
