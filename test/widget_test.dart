// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' show AppLifecycleState, MaterialApp, OutlinedButton;
import 'package:foxsecura_mobile/catalog_update_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foxsecura_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SlowCatalogStore implements CatalogStore {
  final pending = Completer<String?>();

  @override
  Future<String?> read(String key) {
    if (key == CatalogUpdateManager.activeKey) return pending.future;
    return Future<String?>.value(null);
  }

  @override
  Future<void> write(String key, String value) async {}
}

void main() {
  testWidgets('FoxSecura dashboard renders on launch', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const FoxSecuraApp());
    await tester.pumpAndSettle();

    expect(find.text('FoxSecura'), findsOneWidget);
    expect(find.text('Centre de sécurité'), findsOneWidget);
    expect(find.text('Auditer cet appareil'), findsOneWidget);
  });
  testWidgets('migrates legacy URL history before displaying it', (tester) async {
    final old = jsonEncode({
      'time': DateTime.now().toUtc().toIso8601String(),
      'type': 'Vérification URL',
      'detail': 'https://user:password@example.com/path?token=secret',
      'warning': true,
    });
    SharedPreferences.setMockInitialValues({
      'foxsecura_history': <String>[old],
    });
    await tester.pumpWidget(const FoxSecuraApp());
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getStringList('foxsecura_history')!;
    expect(migrated.single, contains('https://example.com'));
    expect(migrated.single, isNot(contains('password')));
    expect(migrated.single, isNot(contains('token')));
  });

  testWidgets('rechecks retention on opening the history tab', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const FoxSecuraApp());
    await tester.pumpAndSettle();

    final expired = jsonEncode({
      'time': DateTime.now().toUtc()
          .subtract(const Duration(days: 31)).toIso8601String(),
      'type': 'Audit appareil',
      'detail': 'Android 14',
      'warning': false,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('foxsecura_history', [expired]);

    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();

    expect(prefs.getStringList('foxsecura_history'), isEmpty);
    expect(find.text('Aucune analyse enregistrée.'), findsOneWidget);
  });

  testWidgets('rechecks retention on app resume', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const FoxSecuraApp());
    await tester.pumpAndSettle();

    final expired = jsonEncode({
      'time': DateTime.now().toUtc()
          .subtract(const Duration(days: 31)).toIso8601String(),
      'type': 'Audit appareil',
      'detail': 'Android 14',
      'warning': false,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('foxsecura_history', [expired]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(prefs.getStringList('foxsecura_history'), isEmpty);
  });
  testWidgets('file scan stays disabled until signed cache restoration completes',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SlowCatalogStore();
    final manager = CatalogUpdateManager(
      store: store,
      trustedPublicKey: List<int>.filled(32, 3),
    );
    await tester.pumpWidget(MaterialApp(
      home: Dashboard(catalogueManager: manager),
    ));
    await tester.pump();
    final finder = find.widgetWithText(
      OutlinedButton, 'Choisir et analyser un fichier');
    expect(tester.widget<OutlinedButton>(finder).onPressed, isNull);

    store.pending.complete(null);
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(finder).onPressed, isNotNull);
  });

}
