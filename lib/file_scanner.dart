// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'signature_catalog.dart';

/// The sole bundled signature is the harmless EICAR test string.
/// A non-match does NOT mean a file is safe.
class FileScanResult {
  const FileScanResult(this.name, this.sha256, this.testSignatureFound, this.bytes);
  final String name;
  final String sha256;
  final bool testSignatureFound;
  final int bytes;
}

class FileScanner {
  static const int maxBytes = 25 * 1024 * 1024;
  static const String eicarSha256 =
      '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f';

  static Future<FileScanResult?> pickAndScan() async {
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
    return scanLocalFile(File(entry.path!), displayName: entry.name);
  }

  static Future<FileScanResult> scanLocalFile(File file, {String? displayName}) async {
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw StateError('La sélection ne correspond pas à un fichier régulier.');
    }
    if (stat.size > maxBytes) {
      throw StateError('Fichier trop volumineux : maximum 25 Mio.');
    }
    // Streaming keeps file contents out of app history and avoids full-file buffering.
    final digest = await sha256.bind(file.openRead()).first;
    final hash = digest.toString();
    return FileScanResult(
      displayName ?? file.uri.pathSegments.last, hash, SignatureCatalog.matchHash(hash)?.isTestOnly == true, stat.size);
  }
}
