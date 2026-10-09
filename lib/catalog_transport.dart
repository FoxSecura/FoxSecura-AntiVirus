// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:io';
import 'dart:typed_data';

import 'catalog_update_manager.dart';
import 'signed_catalog_verifier.dart';

/// Fixed endpoints, HTTPS only, no redirects or credentials.
class HttpsCatalogTransport {
  static const Duration timeout = Duration(seconds: 12);

  static void validateBase(Uri base) {
    if (base.scheme != 'https' || base.host.isEmpty ||
        base.userInfo.isNotEmpty || base.hasQuery || base.hasFragment ||
        base.port != 443 || !base.path.endsWith('/')) {
      throw const FormatException('Origine HTTPS de catalogue invalide');
    }
  }

  static Future<Uint8List> _download(Uri uri, int maximum) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..autoUncompress = false;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('Réponse HTTP de catalogue invalide');
      }
      if (response.contentLength > maximum) {
        throw StateError('Réponse de catalogue trop volumineuse');
      }
      final chunks = BytesBuilder(copy: false);
      var count = 0;
      await for (final chunk in response.timeout(timeout)) {
        count += chunk.length;
        if (count > maximum) {
          throw StateError('Réponse de catalogue trop volumineuse');
        }
        chunks.add(chunk);
      }
      return chunks.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  static Future<VerifiedCatalog> update({
    required Uri base,
    required CatalogUpdateManager manager,
  }) async {
    validateBase(base);
    if (!manager.isConfigured) {
      throw StateError('Mises à jour désactivées : clé éditeur absente');
    }
    final payload = await _download(
      base.resolve('catalog.json'),
      SignedCatalogVerifier.maximumBytes,
    );
    final signature = await _download(base.resolve('catalog.json.sig'), 64);
    return manager.activate(payload: payload, signature: signature);
  }
}
