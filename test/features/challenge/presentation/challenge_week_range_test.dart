// Task 16 — rentang tanggal satu minggu tantangan (`challenge_week_range.dart`).
//
// Aturan mengikat yang test ini kunci:
// - U90: `weekKey` (Senin) → rentang Senin..Minggu, format lokal, bulan
//   tidak diulang saat kedua ujung ada di bulan yang sama.
// - U91: NOL literal `'id_ID'` di mana pun dalam `lib/features/challenge/`.
//
// KOREKSI angka contoh — lihat dartdoc `challenge_week_range.dart` dan
// laporan Task 16: brief/desain menulis "30 Agu–5 Sep" untuk `weekKey`
// 20260831, tapi 31 Agustus 2026 sungguh jatuh hari SENIN (`date -d
// 2026-08-31` → Monday) dan `weekKeyOf`/`daysLeftInWeek` mengunci `weekKey`
// sebagai dayKey Senin — rentang yang konsisten dengan kode adalah
// "31 Agu–6 Sep", bukan "30 Agu–5 Sep". Test di sini mengunci nilai yang
// BENAR, bukan menyalin contoh yang tidak pernah dihitung ulang — persis
// alasan Rev 5 desain mengoreksi pasangan Rupiah "141.000 → 120.000".
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:penyintas_app/features/challenge/presentation/utils/challenge_week_range.dart';

void main() {
  // `DateFormat('d MMM', locale)` melempar `LocaleDataException` tanpa ini —
  // preseden `streak_calendar_test.dart:37`.
  setUpAll(initializeDateFormatting);

  /// Bangun `MaterialApp` minimal dan tangkap hasil `challengeWeekRange`
  /// dari dalam `Builder` — fungsi ini murni butuh `BuildContext` untuk
  /// `Localizations.localeOf`, tidak butuh delegate `AppLocalizations`.
  Future<String> ambil(
    WidgetTester tester,
    int weekKey, {
    String locale = 'id',
  }) async {
    late String hasil;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        // WAJIB — `supportedLocales` MaterialApp default `[Locale('en',
        // 'US')]`. Tanpa mendaftarkan 'id' di sini, algoritma resolusi
        // locale bawaan JATUH ke 'en' walau `locale:` di atas eksplisit
        // 'id' — `Localizations.localeOf(context)` diam-diam melaporkan
        // 'en', dan `DateFormat('d MMM', 'en')` merender "Aug", bukan
        // "Agu" (ditemukan lewat kegagalan test U90 sungguhan, bukan
        // ditebak).
        supportedLocales: const [Locale('id'), Locale('en')],
        // WAJIB juga — begitu 'id' terdaftar di `supportedLocales`,
        // `WidgetsApp` menuntut ADA delegate Material/Cupertino yang
        // sungguh mendukung 'id' (defaultnya hanya 'en'), kalau tidak ia
        // melempar galat "locale not supported by all delegates". Preseden
        // persis: `app.dart:106-109` (MaterialApp produksi) dan
        // `streak_calendar_test.dart:82-84`.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            hasil = challengeWeekRange(context, weekKey);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return hasil;
  }

  // ── U90 · rentang lintas bulan ──────────────────────────────────────────

  testWidgets('U90 · weekKey 20260831 (Senin), locale id → "31 Agu–6 Sep"', (
    tester,
  ) async {
    final hasil = await ambil(tester, 20260831);
    expect(hasil, '31 Agu–6 Sep');
  });

  testWidgets('U90 · weekKey 20260831 (Senin), locale en → "31 Aug–6 Sep"', (
    tester,
  ) async {
    final hasil = await ambil(tester, 20260831, locale: 'en');
    expect(hasil, '31 Aug–6 Sep');
  });

  // ── U90 · minggu dalam satu bulan — bulan tidak diulang ──────────────────

  testWidgets(
    'U90 · weekKey 20260907 (Senin, minggu dalam satu bulan) → "7–13 Sep"',
    (tester) async {
      final hasil = await ambil(tester, 20260907);
      expect(hasil, '7–13 Sep');
    },
  );

  // ── U91 · nol literal id_ID di lib/features/challenge/ ───────────────────

  test(
    'U91 · lib/features/challenge/ tidak mengandung literal id_ID',
    () async {
      final result = await Process.run('grep', [
        '-R',
        '-F',
        '-l',
        'id_ID',
        'lib/features/challenge/',
      ]);
      expect(
        result.exitCode,
        1,
        reason:
            'ditemukan literal id_ID di lib/features/challenge/. '
            'stdout: ${result.stdout}',
      );
    },
  );
}
