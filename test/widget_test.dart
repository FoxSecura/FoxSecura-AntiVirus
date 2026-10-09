// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

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
}
