// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

/// Minimize sensitive data retained in local history.
/// Full URLs may contain credentials, query tokens, or private paths.
class HistoryPrivacy {
  static String urlHostOnly(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'URL invalide (détails non conservés)';
    }
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static String fileSummary() => 'Fichier sélectionné (nom non conservé)';
}
