import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security.dart';

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

class _DashboardState extends State<Dashboard> {
  final url = TextEditingController();
  final history = <String>[];
  AuditReport? audit;
  UrlResult? inspected;
  String? message;
  bool loading = false;
  int section = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => history.addAll(prefs.getStringList('foxsecura_history') ?? []));
  }

  Future<void> _record(String kind, String detail, bool warning) async {
    final item = jsonEncode({
      'time': DateTime.now().toIso8601String(),
      'type': kind,
      'detail': detail,
      'warning': warning,
    });
    setState(() {
      history.insert(0, item);
      if (history.length > 30) history.removeRange(30, history.length);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('foxsecura_history', history);
  }

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
    await _record('Vérification URL', url.text.trim(), result.hasWarning);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('foxsecura_history');
    setState(() => history.clear());
  }

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
    const Text('Historique local non chiffré. Ne saisis pas d’URL contenant des secrets.'),
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
      onDestinationSelected: (value) => setState(() => section = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Sécurité'),
        NavigationDestination(icon: Icon(Icons.link), label: 'Liens'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
      ],
    ),
  );
}
