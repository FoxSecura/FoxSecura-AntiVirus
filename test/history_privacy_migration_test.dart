// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 FoxSecura contributors

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:foxsecura_mobile/history_privacy.dart';

void main() {
  final now = DateTime.utc(2026, 10, 9, 20);
  String record(DateTime date, String type, String detail,
      {bool warning = false}) => jsonEncode({
        'time': date.toIso8601String(),
        'type': type,
        'detail': detail,
        'warning': warning,
      });

  test('removes secrets from legacy URLs on migration', () {
    final old = record(now.subtract(const Duration(days: 1)),
      'Vérification URL',
      'https://alice:secret@example.com/private/file?token=sensitive#frag',
      warning: true);
    final output = HistoryPrivacy.sanitizeStoredRecords([old], now: now);
    final decoded = jsonDecode(output.single) as Map<String, dynamic>;
    expect(decoded['detail'], 'https://example.com');
    expect(decoded['warning'], isTrue);
    expect(output.single, isNot(contains('secret')));
    expect(output.single, isNot(contains('token')));
  });

  test('removes historical file names and arbitrary unknown content', () {
    final rows = [
      record(now, 'Analyse signature de test', '/private/report.secret'),
      record(now, 'Custom event', 'api-token-do-not-save'),
    ];
    final result = HistoryPrivacy.sanitizeStoredRecords(rows, now: now);
    expect(result.join(' '), isNot(contains('report.secret')));
    expect(result.join(' '), isNot(contains('api-token')));
    expect(result.join(' '), contains(HistoryPrivacy.fileSummary()));
    expect(result.join(' '), contains('Détails non conservés'));
  });

  test('rejects invalid, old and future-dated entries', () {
    final rows = [
      'not json',
      '{"time":"invalid","type":"Vérification URL"}',
      record(now.subtract(const Duration(days: 31)), 'Audit appareil', 'Android 12'),
      record(now.add(const Duration(minutes: 7)), 'Audit appareil', 'Android 13'),
      record(now, 'Audit appareil', 'iOS 17.1'),
    ];
    final result = HistoryPrivacy.sanitizeStoredRecords(rows, now: now);
    expect(result, hasLength(1));
    expect(result.single, contains('iOS 17.1'));
  });

  test('keeps only thirty newest rows in chronological order', () {
    final rows = List.generate(45, (i) =>
      record(now.subtract(Duration(hours: i)), 'Audit appareil', 'Android 14'));
    final output = HistoryPrivacy.sanitizeStoredRecords(rows.reversed, now: now);
    expect(output, hasLength(30));
    final dates = output.map((s) => DateTime.parse(
      (jsonDecode(s) as Map<String, dynamic>)['time'] as String)).toList();
    expect(dates.first, now);
    expect(dates.last, now.subtract(const Duration(hours: 29)));
  });

  test('does not retain malformed platform metadata', () {
    final result = HistoryPrivacy.sanitizeStoredRecords([
      record(now, 'Audit appareil', 'Android 14\nSecret: password')
    ], now: now);
    expect(result.single, isNot(contains('password')));
  });

  test('normalizes offsets to UTC instants for retention', () {
    final stamped = jsonEncode({
      'time': '2026-10-09T21:00:00+02:00',
      'type': 'Audit appareil',
      'detail': 'iOS 17.1',
      'warning': false,
    });
    final result = HistoryPrivacy.sanitizeStoredRecords([stamped], now: now);
    expect(result, hasLength(1));
    final data = jsonDecode(result.single) as Map<String, dynamic>;
    expect(data['time'], '2026-10-09T19:00:00.000Z');
  });

  test('rejects expired offset timestamps despite travel', () {
    final stamped = jsonEncode({
      'time': '2026-09-09T14:00:00+14:00',
      'type': 'Audit appareil',
      'detail': 'Android 14',
      'warning': false,
    });
    expect(HistoryPrivacy.sanitizeStoredRecords([stamped], now: now), isEmpty);
  });

  test('drops ambiguous legacy local timestamps without zone', () {
    final stamped = jsonEncode({
      'time': '2026-10-09T20:00:00.000',
      'type': 'Vérification URL',
      'detail': 'https://alice:secret@example.com/?token=secret',
      'warning': true,
    });
    expect(HistoryPrivacy.sanitizeStoredRecords([stamped], now: now), isEmpty);
  });

  test('does not keep invalid URL input or oversized domain in history', () {
    expect(HistoryPrivacy.urlHostOnly('malformed user token'),
      contains('URL invalide'));
    final longHost = 'https://${'a' * 305}.test/private';
    expect(HistoryPrivacy.urlHostOnly(longHost), contains('Domaine trop long'));
  });
}
