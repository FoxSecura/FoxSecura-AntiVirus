// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:foxsecura_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      'time': DateTime.now().toIso8601String(),
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

}
