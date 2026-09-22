import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';

/// Label rentang tanggal satu minggu tantangan, dari `weekKey` (dayKey Senin
/// minggu itu — lihat dartdoc `weekKeyOf`, `challenge_calculator.dart`).
///
/// Dipakai baris riwayat (`ChallengeHistoryList`) DAN eyebrow kartu hasil
/// (`ChallengeResultCard.rangeLabel`, Task 15).
///
/// **Locale WAJIB dari `context`** (`Localizations.localeOf`), BUKAN locale
/// Indonesia yang di-hardcode — persis pelanggaran yang `date_helper.dart:
/// 56,60` sudah tanam (lihat literalnya di sana) dan yang U91 melarang
/// bertambah di `lib/features/challenge/` (test ini sendiri sengaja TIDAK
/// mengeja literal itu, supaya grep U91 tidak menganggap dartdoc ini sebagai
/// pelanggaran). Preseden pola locale-dari-context: `bill_item.dart:78-79`.
///
/// Bulan TIDAK diulang kalau kedua ujung jatuh di bulan yang sama
/// (`"7–13 Sep"`), supaya label tetap ringkas di baris riwayat 56dp.
///
/// KOREKSI terhadap brief/desain — lihat laporan Task 16: `weekKeyOf`
/// (`challenge_calculator.dart:157-161`) dan `daysLeftInWeek` ("Senin = 7,
/// Minggu = 1") sama-sama mengunci `weekKey` sebagai dayKey SENIN, sehingga
/// rentang yang konsisten dengan seluruh basis kode adalah
/// `[weekKey, weekKey + 6]` (Senin..Minggu) — BUKAN `[weekKey - 1, weekKey +
/// 5]` yang dipakai contoh "30 Agu–5 Sep" di brief/mock desain. Untuk
/// `weekKey` 20260831 (Senin), 31 Agustus 2026 memang jatuh hari Senin
/// (diverifikasi lewat `date -d 2026-08-31`), jadi rentang yang benar adalah
/// "31 Agu–6 Sep". Fungsi ini mengikuti `weekKeyOf`/`daysLeftInWeek` — bukan
/// contoh yang tidak pernah dihitung ulang — persis alasan Rev 5 desain
/// mengoreksi pasangan Rupiah "141.000 → 120.000" jadi "140.000 → 115.000".
String challengeWeekRange(BuildContext context, int weekKey) {
  final locale = Localizations.localeOf(context).languageCode;
  final start = localMidnightOf(weekKey);
  final end = localMidnightOf(addDays(weekKey, 6));

  final dayMonthFormat = DateFormat('d MMM', locale);
  final dayOnlyFormat = DateFormat('d', locale);

  // Bulan tidak diulang bila kedua ujung ada di bulan (dan tahun) yang sama.
  final startLabel = (start.month == end.month && start.year == end.year)
      ? dayOnlyFormat.format(start)
      : dayMonthFormat.format(start);
  final endLabel = dayMonthFormat.format(end);

  return '$startLabel–$endLabel';
}
