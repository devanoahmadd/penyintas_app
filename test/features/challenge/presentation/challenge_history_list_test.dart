// Task 16 — riwayat tantangan mingguan (`challenge_history_list.dart`).
//
// Aturan mengikat (spec §7.8, brief Task 16) yang test ini kunci:
// - U84: baris tanpa kategori (`held`/`skipped` tanpa tantangan) merender
//   "—" di kolom kategori.
// - U85: baris berstatus `unknown` merender "—" TANPA ikon ✓/✗.
// - Kegagalan (`missed`) TIDAK diwarnai merah — ikon ✗ memakai `muted*`,
//   BUKAN `warn`.
// - U92: baris riwayat tinggi ≥ 56dp.
// - Maksimal `kChallengeHistoryWeeks` (12) baris dirender walau `history`
//   yang dikirim lebih panjang.
// - Pohon widget TIDAK mengimpor `app_database.dart` (S-C).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_history_list.dart';

/// Delegate sinkron — pola dari `active_challenge_card_test.dart` (Task 14).
class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._value);
  final AppLocalizations _value;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(_value);
  @override
  bool shouldReload(_) => false;
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // `challengeWeekRange` (dipanggil tiap baris) memakai `DateFormat` —
    // tanpa ini, `LocaleDataException` (preseden `streak_calendar_test.dart:37`).
    initializeDateFormatting();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  ChallengeWeek week({
    required int weekKey,
    required ChallengeStatus status,
    String? category = 'food',
    int? finalSpent = 118500,
  }) => ChallengeWeek(
    weekKey: weekKey,
    category: category,
    targetAmount: 120000,
    baselineAmount: 140000,
    status: status,
    finalSpent: finalSpent,
    resolvedAt: DateTime(2026, 9, 7, 6),
    resultSeenAt: DateTime(2026, 9, 7, 7),
  );

  Widget bungkus(Widget child, {bool isDark = false}) => MaterialApp(
    locale: const Locale('id'),
    // WAJIB — lihat `challenge_week_range_test.dart` untuk alasannya:
    // `supportedLocales` bawaan MaterialApp cuma `en`, dan tiap baris di
    // sini memanggil `challengeWeekRange` yang membaca
    // `Localizations.localeOf(context)`.
    supportedLocales: const [Locale('id'), Locale('en')],
    // WAJIB juga — begitu 'id' terdaftar di `supportedLocales`, `WidgetsApp`
    // menuntut delegate Material/Cupertino yang sungguh mendukung 'id'.
    // Preseden: `app.dart:106-109`, `streak_calendar_test.dart:82-84`.
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(brightness: Brightness.light),
    darkTheme: ThemeData(brightness: Brightness.dark),
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  // ── U84 · baris tanpa kategori ────────────────────────────────────────────

  testWidgets('U84 · baris held tanpa kategori merender "—"', (tester) async {
    await tester.pumpWidget(
      bungkus(
        ChallengeHistoryList(
          history: [
            week(
              weekKey: 20260831,
              status: ChallengeStatus.held,
              category: null,
            ),
          ],
        ),
      ),
    );

    expect(
      find.text('—'),
      findsOneWidget,
      reason: 'kolom kategori baris held tanpa tantangan harus "—"',
    );
  });

  // ── U85 · baris unknown ───────────────────────────────────────────────────

  testWidgets('U85 · baris unknown merender "—" TANPA ikon check/close', (
    tester,
  ) async {
    await tester.pumpWidget(
      bungkus(
        ChallengeHistoryList(
          history: [
            week(
              weekKey: 20260831,
              status: ChallengeStatus.unknown,
              category: 'food',
            ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const Key('challenge-history-icon-0')),
      findsNothing,
      reason: 'baris unknown tidak boleh punya ikon ✓/✗ apa pun',
    );
    expect(
      find.byKey(const Key('challenge-history-trailing-0')),
      findsOneWidget,
    );
    expect(
      (tester.widget(find.byKey(const Key('challenge-history-trailing-0')))
              as Text)
          .data,
      '—',
    );
  });

  // ── Kegagalan tidak diwarnai merah ────────────────────────────────────────

  testWidgets('missed · ikon ✗ berwarna muted (light), BUKAN warn', (
    tester,
  ) async {
    await tester.pumpWidget(
      bungkus(
        ChallengeHistoryList(
          history: [week(weekKey: 20260831, status: ChallengeStatus.missed)],
        ),
      ),
    );

    final icon =
        tester.widget(find.byKey(const Key('challenge-history-icon-0')))
            as Icon;
    expect(icon.icon, Icons.close_rounded);
    expect(icon.color, AppColors.mutedLight);
    expect(icon.color, isNot(AppColors.warn));
  });

  testWidgets('missed · ikon ✗ berwarna muted (dark), BUKAN warn', (
    tester,
  ) async {
    await tester.pumpWidget(
      bungkus(
        ChallengeHistoryList(
          history: [week(weekKey: 20260831, status: ChallengeStatus.missed)],
        ),
        isDark: true,
      ),
    );

    final icon =
        tester.widget(find.byKey(const Key('challenge-history-icon-0')))
            as Icon;
    expect(icon.color, AppColors.mutedDark);
    expect(icon.color, isNot(AppColors.warn));
  });

  testWidgets('achieved · ikon ✓ berwarna primary (light)', (tester) async {
    await tester.pumpWidget(
      bungkus(
        ChallengeHistoryList(
          history: [week(weekKey: 20260831, status: ChallengeStatus.achieved)],
        ),
      ),
    );

    final icon =
        tester.widget(find.byKey(const Key('challenge-history-icon-0')))
            as Icon;
    expect(icon.icon, Icons.check_rounded);
    expect(icon.color, AppColors.primary);
  });

  testWidgets('achieved · ikon ✓ berwarna shoot (dark)', (tester) async {
    await tester.pumpWidget(
      bungkus(
        ChallengeHistoryList(
          history: [week(weekKey: 20260831, status: ChallengeStatus.achieved)],
        ),
        isDark: true,
      ),
    );

    final icon =
        tester.widget(find.byKey(const Key('challenge-history-icon-0')))
            as Icon;
    expect(icon.color, AppColors.shoot);
  });

  testWidgets('held/skipped · ikon "•" berwarna muted', (tester) async {
    await tester.pumpWidget(
      bungkus(
        ChallengeHistoryList(
          history: [
            week(
              weekKey: 20260831,
              status: ChallengeStatus.skipped,
              category: null,
            ),
          ],
        ),
      ),
    );

    final icon =
        tester.widget(find.byKey(const Key('challenge-history-icon-0')))
            as Icon;
    expect(icon.icon, Icons.fiber_manual_record);
    expect(icon.color, AppColors.mutedLight);
  });

  // ── U92 · hit target baris riwayat ≥ 56dp ─────────────────────────────────

  testWidgets('U92 · tinggi baris riwayat ≥ 56', (tester) async {
    await tester.pumpWidget(
      bungkus(
        ChallengeHistoryList(
          history: [week(weekKey: 20260831, status: ChallengeStatus.achieved)],
        ),
      ),
    );

    final size = tester.getSize(
      find.byKey(const Key('challenge-history-row-0')),
    );
    expect(size.height, greaterThanOrEqualTo(56));
  });

  // ── Batas kChallengeHistoryWeeks (12) ────────────────────────────────────

  testWidgets('15 baris riwayat dikirim → hanya 12 baris dirender', (
    tester,
  ) async {
    // weekKey harus dayKey Senin yang SAH (yyyymmdd) — sekadar mengurangi 7
    // dari int-nya bisa mendarat di tanggal tak sah (mis. "hari 0"). Hitung
    // lewat DateTime sungguhan, 15 Senin berturut mundur dari 2026-09-07.
    int senin(int mundurMinggu) {
      final d = DateTime(2026, 9, 7).subtract(Duration(days: 7 * mundurMinggu));
      return d.year * 10000 + d.month * 100 + d.day;
    }

    final limaBelasMinggu = [
      for (var i = 0; i < 15; i++)
        week(weekKey: senin(i), status: ChallengeStatus.achieved),
    ];

    await tester.pumpWidget(
      bungkus(ChallengeHistoryList(history: limaBelasMinggu)),
    );

    expect(
      find.byKey(const Key('challenge-history-row-11')),
      findsOneWidget,
      reason: 'baris ke-12 (index 11) harus tetap dirender',
    );
    expect(
      find.byKey(const Key('challenge-history-row-12')),
      findsNothing,
      reason: 'baris ke-13 (index 12) tidak boleh dirender — melebihi batas',
    );
  });

  // ── S-C · pohon widget tidak mengimpor app_database.dart ────────────────

  test(
    'S-C · challenge_history_list.dart tidak mengimpor app_database.dart',
    () async {
      final result = await Process.run('grep', [
        '-F',
        '-l',
        'app_database.dart',
        'lib/features/challenge/presentation/widgets/challenge_history_list.dart',
      ]);
      expect(
        result.exitCode,
        1,
        reason:
            'challenge_history_list.dart mengimpor app_database.dart. '
            'stdout: ${result.stdout}',
      );
    },
  );
}
