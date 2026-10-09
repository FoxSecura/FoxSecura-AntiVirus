// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

/// Small, versioned offline signature catalogue.
/// This catalogue currently contains only the harmless EICAR test pattern.
/// It is NOT a malware threat intelligence database.
class SignatureEntry {
  const SignatureEntry({
    required this.id,
    required this.sha256,
    required this.description,
    required this.isTestOnly,
  });

  final String id;
  final String sha256;
  final String description;
  final bool isTestOnly;
}

class SignatureCatalog {
  static const String version = '2026.10-test.1';
  static const List<SignatureEntry> entries = [
    SignatureEntry(
      id: 'EICAR-TEST-FILE',
      sha256: '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f',
      description: 'Fichier de test antivirus EICAR (inoffensif)',
      isTestOnly: true,
    ),
  ];

  static SignatureEntry? matchHash(String hash) {
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) return null;
    final normalized = hash.toLowerCase();
    for (final entry in entries) {
      if (entry.sha256 == normalized) return entry;
    }
    return null;
  }
}
