// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:convert';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security.dart';
import 'file_scanner.dart';
import 'history_privacy.dart';
import 'catalog_update_manager.dart';
import 'catalog_transport.dart';
import 'signed_catalog_verifier.dart';

void main() => runApp(const FoxSecuraApp());

const mint = Color(0xFF40E0BF);
const dark = Color(0xFF091522);

class FoxSecuraApp extends StatelessWidget {
  const FoxSecuraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FoxSecura Antivirus',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dark,
      colorScheme: ColorScheme.fromSeed(seedColor: mint, brightness: Brightness.dark),
      cardTheme: CardThemeData(color: const Color(0xFF142637)),
    ),
    home: const Dashboard(),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final url = TextEditingController();
  final history = <String>[];
  AuditReport? audit;
  UrlResult? inspected;
  FileScanResult? fileResult;
  VerifiedCatalog? activeCatalog;
  String? catalogueMessage;
  bool catalogueLoading = false;
  late final CatalogUpdateManager catalogueManager = CatalogUpdateManager(
    store: const PreferencesCatalogStore(),
    trustedPublicKey: CatalogTrustConfig.pinnedPublicKey(),
  );
  String? message;
  bool loading = false;
  int section = 0;
  late Future<void> _historyQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _historyQueue = _load().catchError((Object error, StackTrace stack) {
      debugPrint('Chargement de l’historique impossible : $error');
    });
    _loadCatalogue();
  }

  // Queue every history read/write so a refresh cannot overwrite a scan,
  // or restore entries that were just deleted by the user.
  Future<void> _enqueueHistory(Future<void> Function() work) {
    final operation = _historyQueue.then((_) => work());
    _historyQueue = operation.catchError((Object error, StackTrace stack) {
      debugPrint('Opération sur l’historique impossible : $error');
    });
    return operation;
  }

  void _refreshHistory() {
    _enqueueHistory(_load).catchError((Object error, StackTrace stack) {
      debugPrint('Actualisation de l’historique impossible : $error');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshHistory();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('foxsecura_history') ?? <String>[];
    final sanitized = HistoryPrivacy.sanitizeStoredRecords(stored);
    if (!listEquals(stored, sanitized)) {
      // Remove historic full URLs, file names and expired records on upgrade.
      await prefs.setStringList('foxsecura_history', sanitized);
    }
    if (!mounted) return;
    setState(() {
      history
        ..clear()
        ..addAll(sanitized);
    });
  }

  Future<void> _record(String kind, String detail, bool warning) =>
      _enqueueHistory(() async {
        if (!mounted) return;
        final item = jsonEncode({
          'time': DateTime.now().toUtc().toIso8601String(),
          'type': kind,
          'detail': detail,
          'warning': warning,
        });
        final sanitized = HistoryPrivacy.sanitizeStoredRecords([item, ...history]);
        setState(() {
          history
            ..clear()
            ..addAll(sanitized);
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('foxsecura_history', sanitized);
      });

  Future<void> _audit() async {
    setState(() { loading = true; message = null; });
    try {
      final report = await DeviceAuditor.audit();
      if (!mounted) return;
      setState(() => audit = report);
      await _record('Audit appareil', report.platform,
        report.findings.any((f) => f.severity == 'warning'));
    } catch (e) {
      if (mounted) setState(() => message = 'Audit impossible : $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _inspect() async {
    final result = UrlInspector.inspect(url.text);
    setState(() => inspected = result);
    await _record('Vérification URL', HistoryPrivacy.urlHostOnly(url.text), result.hasWarning);
  }


  Future<void> _loadCatalogue() async {
    final loaded = await catalogueManager.load();
    if (mounted) setState(() => activeCatalog = loaded);
  }

  Future<void> _updateCatalogue() async {
    if (catalogueLoading || !catalogueManager.isConfigured ||
        CatalogTrustConfig.updateBaseUrl.isEmpty) return;
    setState(() { catalogueLoading = true; catalogueMessage = null; });
    try {
      final verified = await HttpsCatalogTransport.update(
        base: Uri.parse(CatalogTrustConfig.updateBaseUrl),
        manager: catalogueManager,
      );
      if (mounted) setState(() {
        activeCatalog = verified;
        catalogueMessage = 'Catalogue signé activé : ' + verified.version;
      });
    } catch (error) {
      if (mounted) setState(() =>
          catalogueMessage = 'Mise à jour refusée : $error');
    } finally {
      if (mounted) setState(() => catalogueLoading = false);
    }
  }

  Future<void> _scanFile() async {
    if (loading) return;
    setState(() { loading = true; message = null; });
    try {
      final result = await FileScanner.pickAndScan(catalogue: activeCatalog);
      if (!mounted || result == null) return;
      setState(() => fileResult = result);
      // Never persist a selected file's contents or its full path.
      await _record('Analyse signature de test', HistoryPrivacy.fileSummary(), result.testSignatureFound);
    } catch (e) {
      if (mounted) setState(() => message = 'Analyse impossible : $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _clearHistory() => _enqueueHistory(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('foxsecura_history');
        if (mounted) setState(() => history.clear());
      });

  Widget _finding(Finding item) => Card(
    child: ListTile(
      leading: Icon(item.severity == 'warning'
        ? Icons.warning_amber_rounded : Icons.info_outline,
        color: item.severity == 'warning' ? Colors.orangeAccent : mint),
      title: Text(item.title),
      subtitle: Text(item.details),
    ),
  );

  Widget _home() => ListView(padding: const EdgeInsets.all(18), children: [
    const SizedBox(height: 8),
    const Icon(Icons.shield_outlined, size: 86, color: mint),
    const SizedBox(height: 12),
    const Text('Centre de sécurité', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center),
    const SizedBox(height: 8),
    const Text('Audit des réglages accessibles. Cela ne constitue pas une analyse antivirus complète.',
      textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 24),
    FilledButton.icon(onPressed: loading ? null : _audit,
      icon: const Icon(Icons.radar), label: Text(loading ? 'Analyse en cours...' : 'Auditer cet appareil')),
    if (message != null) Padding(padding: const EdgeInsets.all(12), child: Text(message!,
      style: const TextStyle(color: Colors.orangeAccent))),
    if (audit != null) ...[
      const SizedBox(height: 20),
      Text(audit!.platform, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ...audit!.findings.map(_finding),
    ],
    const SizedBox(height: 20),
    const Text('Fichier sélectionné', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    const Text('Contrôle SHA-256 local contre le catalogue disponible. Un non-match ne prouve pas la sécurité.'),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: loading ? null : _scanFile,
      icon: const Icon(Icons.insert_drive_file_outlined),
      label: const Text('Choisir et analyser un fichier'),
    ),
    if (fileResult != null) Card(child: ListTile(
      leading: Icon(fileResult!.signatureFound
        ? Icons.warning_amber_rounded : Icons.info_outline,
        color: fileResult!.signatureFound ? Colors.orangeAccent : mint),
      title: Text(fileResult!.signatureFound
        ? (fileResult!.testSignatureFound
            ? 'Signature EICAR de test reconnue'
            : 'Correspondance dans le catalogue signé')
        : 'Aucune signature connue reconnue'),
      subtitle: Text('${fileResult!.name} · ${fileResult!.bytes} octets\n'
        'SHA-256 : ${fileResult!.sha256}\n'
        'Catalogue : ' + fileResult!.catalogueVersion + '\n' +
        'Un résultat négatif ne garantit pas la sécurité du fichier.'),
      isThreeLine: true,
    )),

    const SizedBox(height: 20),
    Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Catalogue de signatures',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(activeCatalog == null
          ? 'Mode démonstration EICAR : aucune base de malwares active.'
          : 'Catalogue signé : ' + activeCatalog!.version +
            ' · signatures : ' + activeCatalog!.entries.length.toString()),
        if (!catalogueManager.isConfigured)
          const Padding(padding: EdgeInsets.only(top: 8),
            child: Text('Mises à jour désactivées : clé éditeur absente.',
              style: TextStyle(color: Colors.white70))),
        if (catalogueManager.isConfigured &&
            CatalogTrustConfig.updateBaseUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: catalogueLoading ? null : _updateCatalogue,
            icon: const Icon(Icons.system_update_alt),
            label: Text(catalogueLoading
              ? 'Vérification en cours…' : 'Vérifier les mises à jour'),
          ),
        ],
        if (catalogueMessage != null)
          Text(catalogueMessage!, style: const TextStyle(color: mint)),
      ]),
    )),
    const SizedBox(height: 24),
    Card(child: ListTile(
      leading: const Icon(Icons.link, color: mint),
      title: const Text('Détection de liens suspects'),
      subtitle: const Text('Inspecter un lien avec les règles hors ligne'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => setState(() => section = 1),
    )),
  ]);

  Widget _urls() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Inspection de lien', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    const Text('Analyse heuristique uniquement. Aucune base de réputation n’est consultée.'),
    const SizedBox(height: 18),
    TextField(controller: url, keyboardType: TextInputType.url,
      autocorrect: false, enableSuggestions: false,
      decoration: const InputDecoration(border: OutlineInputBorder(),
        labelText: 'Adresse URL', hintText: 'https://example.com')),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: _inspect,
      icon: const Icon(Icons.search), label: const Text('Inspecter')),
    if (inspected != null) ...[
      const SizedBox(height: 20),
      Text(inspected!.hasWarning ? 'Indicateurs à vérifier' : 'Résultat de l’inspection',
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      ...inspected!.findings.map(_finding),
    ],
  ]);

  Widget _history() => ListView(padding: const EdgeInsets.all(18), children: [
    Row(children: [
      const Expanded(child: Text('Historique local',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      TextButton(onPressed: history.isEmpty ? null : _clearHistory,
        child: const Text('Effacer')),
    ]),
    const Text('Historique local non chiffré : conservation maximale de 30 jours et 30 évènements. N’utilise pas d’URL contenant des secrets.'),
    const SizedBox(height: 12),
    if (history.isEmpty) const Text('Aucune analyse enregistrée.'),
    ...history.map((entry) {
      try {
        final data = jsonDecode(entry) as Map<String, dynamic>;
        return Card(child: ListTile(
          leading: Icon(data['warning'] == true ? Icons.warning_amber : Icons.history,
            color: data['warning'] == true ? Colors.orangeAccent : mint),
          title: Text((data['type'] ?? '').toString()),
          subtitle: Text('${data['detail']}\n${data['time']}'),
          isThreeLine: true,
        ));
      } catch (_) {
        return const SizedBox.shrink();
      }
    }),
  ]);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [
        Icon(Icons.shield, color: mint), SizedBox(width: 8),
        Text('FoxSecura', style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
      backgroundColor: dark,
    ),
    body: SafeArea(child: IndexedStack(index: section,
      children: [_home(), _urls(), _history()])),
    bottomNavigationBar: NavigationBar(
      selectedIndex: section,
      onDestinationSelected: (value) {
        setState(() => section = value);
        if (value == 2) _refreshHistory();
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Sécurité'),
        NavigationDestination(icon: Icon(Icons.link), label: 'Liens'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
      ],
    ),
  );
}
