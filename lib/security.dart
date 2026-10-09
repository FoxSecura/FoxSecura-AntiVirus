// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'package:flutter/services.dart';

class Finding {
  final String title;
  final String details;
  final String severity;
  const Finding(this.title, this.details, this.severity);
}

class AuditReport {
  final String platform;
  final List<Finding> findings;
  const AuditReport(this.platform, this.findings);
}

class DeviceAuditor {
  static const _channel = MethodChannel('foxsecura/device');
  static Future<AuditReport> audit() async {
    final data = await _channel.invokeMapMethod<String, dynamic>('audit')
        .timeout(const Duration(seconds: 10));
    if (data == null) throw StateError('Audit indisponible');
    final entries = data['findings'] as List<dynamic>? ?? const [];
    return AuditReport((data['platform'] ?? 'Inconnu').toString(),
      entries.map((entry) {
        final row = Map<String, dynamic>.from(entry as Map);
        return Finding((row['title'] ?? '').toString(),
          (row['details'] ?? '').toString(),
          (row['severity'] ?? 'info').toString());
      }).toList());
  }
}

class UrlResult {
  final Uri? url;
  final List<Finding> findings;
  const UrlResult(this.url, this.findings);
  bool get hasWarning => findings.any((f) => f.severity == 'warning');
}

/// Heuristics only: no URL reputation or malware database is consulted.
class UrlInspector {
  static UrlResult inspect(String input) {
    final raw = input.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return const UrlResult(null, [
        Finding('URL invalide', 'Saisis une URL absolue http:// ou https://.', 'warning')
      ]);
    }
    final host = uri.host.toLowerCase();
    final findings = <Finding>[];
    if (uri.scheme == 'http') {
      findings.add(const Finding('HTTP non chiffré',
        'Le transport HTTP ne fournit pas le chiffrement HTTPS.', 'warning'));
    }
    if (uri.userInfo.isNotEmpty) {
      findings.add(const Finding('Identifiants dans l’URL',
        'Le caractère @ peut masquer le domaine réel.', 'warning'));
    }
    if (host.contains('xn--')) {
      findings.add(const Finding('Domaine punycode',
        'Vérifie soigneusement l’orthographe du domaine.', 'warning'));
    }
    if (RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$').hasMatch(host) ||
        (host.contains(':') && !host.contains('.'))) {
      findings.add(const Finding('Adresse IP directe',
        'Une IP littérale mérite une vérification manuelle.', 'warning'));
    }
    if (uri.hasPort && uri.port != (uri.scheme == 'https' ? 443 : 80)) {
      findings.add(Finding('Port non standard',
        'Port ${uri.port} : vérifie le service attendu.', 'info'));
    }
    if (host.length > 65 || host.split('.').length > 5) {
      findings.add(const Finding('Domaine complexe',
        'Le nom de domaine est long ou très imbriqué.', 'info'));
    }
    if (findings.isEmpty) {
      findings.add(const Finding('Aucun indicateur local détecté',
        'Ce résultat ne garantit pas que le site soit sûr : aucune réputation en ligne n’a été consultée.', 'info'));
    }
    return UrlResult(uri, findings);
  }
}
