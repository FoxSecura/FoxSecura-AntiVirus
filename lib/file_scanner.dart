// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'signature_catalog.dart';
import 'signed_catalog_verifier.dart';

/// The sole bundled signature is the harmless EICAR test string.
/// A non-match does NOT mean a file is safe.
class FileScanResult {
  const FileScanResult(this.name, this.sha256, this.testSignatureFound, this.bytes,
      {this.matchedSignature, this.catalogueVersion = SignatureCatalog.version});
  final String name;
  final String sha256;
  final bool testSignatureFound;
  final int bytes;
  final SignatureEntry? matchedSignature;
  final String catalogueVersion;
  bool get signatureFound => matchedSignature != null;
}

class FileScanner {
  static const int maxBytes = 25 * 1024 * 1024;
  static const String eicarSha256 =
      '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f';

  static Future<FileScanResult?> pickAndScan({VerifiedCatalog? catalogue}) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final entry = picked.files.single;
    if (entry.path == null) {
      throw StateError('Le fournisseur de fichiers ne donne pas accès au fichier.');
    }
    return scanLocalFile(File(entry.path!), displayName: entry.name, catalogue: catalogue);
  }

  static Future<FileScanResult> scanLocalFile(File file, {String? displayName, VerifiedCatalog? catalogue}) async {
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw StateError('La sélection ne correspond pas à un fichier régulier.');
    }
    if (stat.size > maxBytes) {
      throw StateError('Fichier trop volumineux : maximum 25 Mio.');
    }
    // Enforce the size limit WHILE streaming too: a file may grow after stat().
    // Contents never enter app history and are not fully buffered in memory.
    var bytesRead = 0;
    final bounded = file.openRead().map((chunk) {
      bytesRead += chunk.length;
      if (bytesRead > maxBytes) {
        throw StateError('Fichier trop volumineux : maximum 25 Mio.');
      }
      return chunk;
    });
    final digest = await sha256.bind(bounded).first;
    final hash = digest.toString();
    final entries = catalogue?.entries ?? SignatureCatalog.entries;
    SignatureEntry? matched;
    for (final entry in entries) {
      if (entry.sha256 == hash) {
        matched = entry;
        break;
      }
    }
    return FileScanResult(
      displayName ?? file.uri.pathSegments.last, hash,
      matched?.isTestOnly == true, bytesRead,
      matchedSignature: matched,
      catalogueVersion: catalogue?.version ?? SignatureCatalog.version);
  }
}
