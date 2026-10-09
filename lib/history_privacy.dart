// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:convert';

/// Privacy boundary for the local history (including data from older releases).
///
/// The store is NOT encrypted. Never preserve full URLs, file names, arbitrary
/// untrusted details, or unknown event types. Expire entries after 30 days.
class HistoryPrivacy {
  static const int maximumEntries = 30;
  static const Duration retention = Duration(days: 30);

  static String urlHostOnly(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'URL invalide (détails non conservés)';
    }
    final summary = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    return summary.length > 300
        ? 'Domaine trop long (détails non conservés)'
        : summary;
  }

  static String fileSummary() => 'Fichier sélectionné (nom non conservé)';

  /// Sanitize legacy rows on read and all new rows before persistence.
  ///
  /// Drop malformed, expired and future-dated entries rather than retaining
  /// unknown sensitive data. The result is newest-first with bounded length.
  static List<String> sanitizeStoredRecords(Iterable<String> rawRecords, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final oldest = reference.subtract(retention);
    final newestAllowed = reference.add(const Duration(minutes: 5));
    final records = <(DateTime, String)>[];

    for (final raw in rawRecords) {
      if (raw.length > 16 * 1024) continue;
      try {
        final data = jsonDecode(raw);
        if (data is! Map<String, dynamic>) continue;
        final timestamp = data['time'];
        if (timestamp is! String) continue;
        final time = DateTime.tryParse(timestamp);
        if (time == null || time.isBefore(oldest) || time.isAfter(newestAllowed)) {
          continue;
        }

        final kind = data['type'];
        final detail = data['detail'];
        String safeType;
        String safeDetail;
        switch (kind) {
          case 'Vérification URL':
            safeType = 'Vérification URL';
            safeDetail = urlHostOnly(detail is String ? detail : '');
          case 'Analyse signature de test':
          case 'Analyse fichier':
            safeType = 'Analyse signature de test';
            safeDetail = fileSummary();
          case 'Audit appareil':
            safeType = 'Audit appareil';
            final platform = detail is String ? detail : '';
            safeDetail = RegExp(r'^(Android|iOS) [A-Za-z0-9._-]{1,32}$')
                    .hasMatch(platform)
                ? platform
                : 'Appareil audité (détails non conservés)';
          default:
            safeType = 'Ancien évènement';
            safeDetail = 'Détails non conservés';
        }

        records.add((
          time,
          jsonEncode({
            'time': time.toIso8601String(),
            'type': safeType,
            'detail': safeDetail,
            'warning': data['warning'] == true,
          }),
        ));
      } on FormatException {
        // Ignore malformed historic records.
      } on TypeError {
        // Ignore records not matching the expected JSON value types.
      }
    }

    records.sort((a, b) => b.$1.compareTo(a.$1));
    return records.take(maximumEntries).map((entry) => entry.$2).toList();
  }
}
