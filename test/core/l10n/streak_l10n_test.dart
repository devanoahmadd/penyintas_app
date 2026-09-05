import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';

/// Jaring parity KHUSUS halaman Konsistensi (Task 12).
///
/// `translations_parity_test.dart` hanya menjamin id.json & en.json punya set
/// key IDENTIK — key yang hilang dari KEDUANYA lolos diam-diam (`_t()`
/// fallback ke nama key, UI menampilkan "consistency_undo" mentah). Daftar
/// EKSPLISIT di bawah menutup celah itu, meniru `bills_l10n_test.dart`.
///
/// Sengaja baca file lewat `dart:io` (bukan `rootBundle`) supaya yang diuji
/// adalah file sumber di repo, bukan salinan asset bundle hasil build.
///
/// `streakKeys` diuji DUA ARAH: test di bawah membuktikan setiap entrinya ada
/// di JSON (arah maju), dan test "arah balik" di paling bawah membuktikan
/// setiap key `consistency_` di id.json terdaftar di `streakKeys` — tanpa
/// arah balik, key baru yang lupa didaftarkan lolos diam-diam.
void main() {
  late Map<String, dynamic> id;
  late Map<String, dynamic> en;
  late AppLocalizations l10nId;
  late AppLocalizations l10nEn;

  setUpAll(() {
    id =
        json.decode(File('assets/translations/id.json').readAsStringSync())
            as Map<String, dynamic>;
    en =
        json.decode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    l10nId = AppLocalizations(const Locale('id'), Map<String, String>.from(id));
    l10nEn = AppLocalizations(const Locale('en'), Map<String, String>.from(en));
  });

  /// Semua key berawalan `consistency_` yang dipakai halaman `/consistency`
  /// (angka streak, chip status, empty/error/restoring, CTA, sheet aturan).
  const streakKeys = [
    'consistency_title',
    'consistency_days_label',
    'consistency_today_done',
    'consistency_today_pending',
    'consistency_today_marked',
    'consistency_today_anomaly',
    'consistency_cta_no_spend',
    'consistency_longest',
    'consistency_grace_left',
    'consistency_empty',
    'consistency_error',
    'consistency_retry',
    'consistency_survival_days',
    'consistency_undo',
    'consistency_marked_snack',
    'consistency_mark_failed',
    'consistency_rules_title',
    'consistency_rules_body',
    'consistency_rules_a11y',
  ];

  test('id.json memuat semua key Konsistensi', () {
    for (final k in streakKeys) {
      expect(id.containsKey(k), isTrue, reason: 'id.json kekurangan "$k"');
    }
  });

  test('en.json memuat semua key Konsistensi', () {
    for (final k in streakKeys) {
      expect(en.containsKey(k), isTrue, reason: 'en.json kekurangan "$k"');
    }
  });

  test('nilai key Konsistensi tidak kosong di kedua bahasa', () {
    for (final k in streakKeys) {
      expect(
        (id[k] as String?)?.trim(),
        isNotEmpty,
        reason: 'nilai "$k" kosong di id.json',
      );
      expect(
        (en[k] as String?)?.trim(),
        isNotEmpty,
        reason: 'nilai "$k" kosong di en.json',
      );
    }
  });

  test('placeholder {days} sama persis di ID & EN', () {
    expect(
      id['consistency_survival_days'] as String,
      contains('{days}'),
      reason: 'id.json "consistency_survival_days" kehilangan placeholder',
    );
    expect(
      en['consistency_survival_days'] as String,
      contains('{days}'),
      reason: 'en.json "consistency_survival_days" kehilangan placeholder',
    );
  });

  test('consistencySurvivalDays(12) menyisipkan angka ke kalimat', () {
    expect(l10nId.consistencySurvivalDays(12), 'Hari ke-12 kamu bertahan');
    expect(l10nEn.consistencySurvivalDays(12), 'Day 12 of holding on');
  });

  test('halaman galat tidak pernah menyalahkan koneksi', () {
    // Kegagalan baca snapshot lokal murni Drift — tak ada jaringan.
    expect(
      (id['consistency_error'] as String).toLowerCase(),
      isNot(contains('koneksi')),
    );
    expect(
      (en['consistency_error'] as String).toLowerCase(),
      isNot(contains('connection')),
    );
  });

  // ── Arah balik: id.json → streakKeys ──
  //
  // Semua test di atas beriterasi dari streakKeys ke JSON (arah maju) — kunci
  // yang ADA di JSON tapi lupa didaftarkan ke streakKeys lolos diam-diam.
  // Test ini menutup arah baliknya.
  test(
    'streakKeys memuat semua key consistency_ yang ada di id.json (arah balik)',
    () {
      final actualStreakKeys = id.keys
          .where((k) => k.startsWith('consistency_'))
          .toSet();
      final missing = actualStreakKeys.difference(streakKeys.toSet());
      expect(
        missing,
        isEmpty,
        reason:
            'kunci consistency_ ada di id.json tapi belum didaftarkan ke '
            'streakKeys: $missing',
      );
    },
  );
}
