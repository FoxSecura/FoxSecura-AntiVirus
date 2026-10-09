// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

import 'signature_catalog.dart';

/// Verifies a detached Ed25519 signature BEFORE interpreting JSON.
/// Verification alone is not enough: production must pin an authentic
/// FoxSecura public key, distribute it via a trusted application update,
/// and persist an anti-rollback version counter.
class SignedCatalogVerifier {
  const SignedCatalogVerifier({required this.trustedPublicKey});

  final List<int> trustedPublicKey;
  static const int maximumBytes = 128 * 1024;

  Future<VerifiedCatalog> verify({
    required List<int> payload,
    required List<int> signature,
    required int minimumSequence,
  }) async {
    if (trustedPublicKey.length != 32 || signature.length != 64) {
      throw const FormatException('Clé ou signature Ed25519 invalide');
    }
    if (payload.isEmpty || payload.length > maximumBytes) {
      throw const FormatException('Taille de manifeste invalide');
    }
    final ok = await Ed25519().verify(
      payload,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(trustedPublicKey, type: KeyPairType.ed25519),
      ),
    );
    if (!ok) throw const FormatException('Signature invalide');
    final decoded = jsonDecode(utf8.decode(payload));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Manifeste JSON invalide');
    }
    final sequence = decoded['sequence'];
    final version = decoded['version'];
    final rawEntries = decoded['entries'];
    if (sequence is! int || sequence <= minimumSequence ||
        sequence < 1 || version is! String ||
        !RegExp(r'^[a-zA-Z0-9._-]{1,48}$').hasMatch(version) ||
        rawEntries is! List || rawEntries.length > 500) {
      throw const FormatException('Version ou catalogue invalide');
    }
    final unique = <String>{};
    final entries = <SignatureEntry>[];
    for (final raw in rawEntries) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Entrée invalide');
      }
      final id = raw['id'];
      final digest = raw['sha256'];
      final description = raw['description'];
      final test = raw['isTestOnly'];
      if (id is! String || !RegExp(r'^[A-Za-z0-9._-]{1,80}$').hasMatch(id) ||
          digest is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(digest) ||
          description is! String || description.length > 200 ||
          test is! bool || !unique.add(digest)) {
        throw const FormatException('Signature de fichier mal formée ou dupliquée');
      }
      entries.add(SignatureEntry(id: id, sha256: digest,
        description: description, isTestOnly: test));
    }
    return VerifiedCatalog(sequence: sequence, version: version, entries: entries);
  }
}

class VerifiedCatalog {
  VerifiedCatalog({
    required this.sequence,
    required this.version,
    required List<SignatureEntry> entries,
  }) : entries = List.unmodifiable(entries);

  final int sequence;
  final String version;
  final List<SignatureEntry> entries;
}
