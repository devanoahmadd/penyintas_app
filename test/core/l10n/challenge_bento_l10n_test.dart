import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';

/// Task 17 — tiga artefak l10n untuk tile bento "Tantangan / Mingguan" +
/// dialog konfirmasi mematikan sakelar di Pengaturan.
///
/// Meniru `streak_l10n_test.dart`: id.json & en.json diuji arah maju (semua
/// key `challengeBentoKeys` ADA di JSON) dan arah balik (semua key
/// `challenge_tile_*`/`challenge_disable_confirm_*` di id.json TERDAFTAR di
/// `challengeBentoKeys`) — supaya key baru yang lupa didaftarkan di salah
/// satu sisi tidak lolos diam-diam.
///
/// Ditambah artefak KETIGA yang tidak dicek `translations_parity_test.dart`
/// (yang hanya menjamin id.json ↔ en.json identik): getter/method di
/// `app_localizations.dart`. `_t()` fallback ke nama key mentah bila getter
/// lupa ditulis — U95 di brief Task 17 — jadi test ini membaca SUMBER
/// `app_localizations.dart` sebagai teks, bukan lewat reflection.
void main() {
  late Map<String, dynamic> id;
  late Map<String, dynamic> en;
  late AppLocalizations l10nId;
  late AppLocalizations l10nEn;
  late String sumberL10n;

  setUpAll(() async {
    id =
        json.decode(File('assets/translations/id.json').readAsStringSync())
            as Map<String, dynamic>;
    en =
        json.decode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    l10nId = AppLocalizations(
      const Locale('id'),
      Map<String, String>.from(id),
    );
    l10nEn = AppLocalizations(
      const Locale('en'),
      Map<String, String>.from(en),
    );
    sumberL10n = await File(
      'lib/core/l10n/app_localizations.dart',
    ).readAsString();
  });

  /// Key BARU Task 17 — tile bento dashboard (`challenge_tile_*`, 7 varian
  /// sesuai tabel spec baris 1465–1478) + dialog konfirmasi mematikan
  /// sakelar (`challenge_disable_confirm_*`, 3 varian, baris 1508–1510).
  const challengeBentoKeys = [
    'challenge_tile_off',
    'challenge_tile_active',
    'challenge_tile_over',
    'challenge_tile_held',
    'challenge_tile_window',
    'challenge_tile_no_data',
    'challenge_tile_budget',
    'challenge_disable_confirm_title',
    'challenge_disable_confirm_body',
    'challenge_disable_confirm_cta',
  ];

  test('id.json memuat semua key tile & dialog Tantangan', () {
    for (final k in challengeBentoKeys) {
      expect(id.containsKey(k), isTrue, reason: 'id.json kekurangan "$k"');
    }
  });

  test('en.json memuat semua key tile & dialog Tantangan', () {
    for (final k in challengeBentoKeys) {
      expect(en.containsKey(k), isTrue, reason: 'en.json kekurangan "$k"');
    }
  });

  test('nilai key tile & dialog Tantangan tidak kosong di kedua bahasa', () {
    for (final k in challengeBentoKeys) {
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

  test('placeholder {category} & {amount} sama persis di ID & EN', () {
    for (final k in ['challenge_tile_active', 'challenge_tile_over']) {
      for (final placeholder in ['{category}', '{amount}']) {
        expect(
          id[k] as String,
          contains(placeholder),
          reason: 'id.json "$k" kehilangan $placeholder',
        );
        expect(
          en[k] as String,
          contains(placeholder),
          reason: 'en.json "$k" kehilangan $placeholder',
        );
      }
    }
  });

  test('challengeTileActive/Over menyisipkan kategori & nominal', () {
    expect(
      l10nId.challengeTileActive('Makan & Minum', 'Rp 34.000'),
      'Makan & Minum · sisa Rp 34.000',
    );
    expect(
      l10nEn.challengeTileActive('Food & Drinks', 'Rp 34.000'),
      'Food & Drinks · Rp 34.000 left',
    );
    expect(
      l10nId.challengeTileOver('Makan & Minum', 'Rp 12.000'),
      'Makan & Minum · lewat Rp 12.000',
    );
    expect(
      l10nEn.challengeTileOver('Food & Drinks', 'Rp 12.000'),
      'Food & Drinks · Rp 12.000 over',
    );
  });

  // ── settledThisWeek & outOfWindow SENGAJA memakai key yang sama ──
  //
  // Koreksi pengendali: `PhaseSettledThisWeek` dan `PhaseOutOfWindow` sama-
  // sama berkata "Mulai Senin depan" ke user (dartdoc `challenge_phase.dart`
  // baris 61-62) — desain yang disengaja, bukan celah. Key `challenge_tile_
  // window` dipakai ULANG oleh keduanya, jadi tidak ada key terpisah untuk
  // `outOfWindow` di daftar `challengeBentoKeys` di atas.
  test(
    'challenge_tile_window dipakai ulang — bukan bug, tapi tidak boleh '
    'kosong',
    () {
      expect(id['challenge_tile_window'], isNotEmpty);
      expect(en['challenge_tile_window'], isNotEmpty);
    },
  );

  // ── Artefak ketiga: getter/method wajib ada di app_localizations.dart ──
  test(
    'tiap key challenge_tile_*/challenge_disable_confirm_* punya getter di '
    'app_localizations.dart',
    () {
      final kurang = challengeBentoKeys
          .where((k) => !sumberL10n.contains("'$k'"))
          .toList();
      expect(
        kurang,
        isEmpty,
        reason:
            'key tanpa getter akan merender nama key mentah di layar: $kurang',
      );
    },
  );

  // ── Arah balik: id.json → challengeBentoKeys ──
  test(
    'challengeBentoKeys memuat semua key challenge_tile_*/challenge_'
    'disable_confirm_* yang ada di id.json (arah balik)',
    () {
      final actual = id.keys
          .where(
            (k) =>
                k.startsWith('challenge_tile_') ||
                k.startsWith('challenge_disable_confirm_'),
          )
          .toSet();
      final missing = actual.difference(challengeBentoKeys.toSet());
      expect(
        missing,
        isEmpty,
        reason:
            'kunci ada di id.json tapi belum didaftarkan ke '
            'challengeBentoKeys: $missing',
      );
    },
  );
}
