import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';

/// Butir 5 (keputusan pemilik repo 2026-09-24) — nada kalimat saat belanja
/// pos tantangan sudah lewat target di TENGAH minggu.
///
/// Versi sebelumnya ("…lanjut ke minggu depan.") terbaca seolah minggu ini
/// sudah selesai: diucapkan hari Rabu, ia mengundang "bebas saja sampai
/// Minggu" padahal belanja empat hari itu tetap menggerus saldo dan
/// Days-to-Live. Versi baru mempertahankan pembuka yang menenangkan, tapi
/// menjaga arah ke sisa minggu ini.
///
/// Dikunci NILAINYA, bukan cuma keberadaan key: tak ada gerbang yang mengunci
/// copy ke tabel spec, dan itu sebabnya penyimpangan ini dulu lolos tiga task
/// berturut-turut tanpa terdeteksi.
void main() {
  late AppLocalizations l10nId;
  late AppLocalizations l10nEn;

  Map<String, String> baca(String kode) => Map<String, String>.from(
    json.decode(File('assets/translations/$kode.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  setUpAll(() {
    l10nId = AppLocalizations(const Locale('id'), baca('id'));
    l10nEn = AppLocalizations(const Locale('en'), baca('en'));
  });

  test('ID — menenangkan, lalu menjaga arah ke sisa minggu ini', () {
    expect(
      l10nId.challengeCardOverHint,
      'Nggak apa-apa. Sisa minggu ini tetap berarti, catat terus ya.',
    );
  });

  test('EN — padanan makna yang sama', () {
    expect(
      l10nEn.challengeCardOverHint,
      "That's okay. The rest of this week still counts, keep logging.",
    );
  });

  test('tidak lagi melepaskan minggu berjalan', () {
    for (final s in [
      l10nId.challengeCardOverHint,
      l10nEn.challengeCardOverHint,
    ]) {
      expect(s.toLowerCase(), isNot(contains('minggu depan')));
      expect(s.toLowerCase(), isNot(contains('next week')));
    }
  });
}
