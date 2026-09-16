// Task 15 — kartu hasil sekali-tampil untuk tantangan mingguan.
//
// Aturan mengikat (spec §7.6/§7.7) yang test ini kunci:
// - Kartu hasil BUKAN phase — dirender DI ATAS phase apa pun, termasuk
//   `disabled` (U78, U82).
// - Menutup diri sendiri untuk status non-achieved/missed (U80).
// - Tombol tutup ≥48dp, `onDismiss` terpanggil TEPAT SEKALI (U79, U92).
// - Latar `surface*`, BUKAN `card*` — banner sementara, bukan permukaan
//   permanen.
// - Nol warna FUNGSIONAL (`warn`/`caution`/`primaryBright`/`success`)
//   dipakai sebagai warna teks/ikon — seluruhnya `textSoft*`.
// - Pohon widget TIDAK mengimpor `app_database.dart` (S-C).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_empty_card.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_result_card.dart';

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
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  ChallengeWeek week({
    int weekKey = 20260824,
    ChallengeStatus status = ChallengeStatus.achieved,
    String? category = 'food',
  }) => ChallengeWeek(
    weekKey: weekKey,
    category: category,
    targetAmount: 100000,
    baselineAmount: 130000,
    status: status,
    finalSpent: 95000,
    resolvedAt: DateTime(2026, 8, 31, 6),
    resultSeenAt: null,
  );

  Widget bungkus(Widget child, {bool isDark = false}) => MaterialApp(
    locale: const Locale('id'),
    localizationsDelegates: [_SyncL10nDelegate(l10n)],
    theme: ThemeData(brightness: Brightness.light),
    darkTheme: ThemeData(brightness: Brightness.dark),
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  Widget kartu({
    ChallengeWeek? w,
    String rangeLabel = '17–23 Agu',
    String line = 'Kamu belanja di bawah target minggu ini.',
    VoidCallback? onDismiss,
    bool isDark = false,
  }) => bungkus(
    ChallengeResultCard(
      week: w ?? week(),
      rangeLabel: rangeLabel,
      line: line,
      onDismiss: onDismiss ?? () {},
    ),
    isDark: isDark,
  );

  // ── U78 · kartu hasil hadir di atas kartu utama dalam urutan pohon ──────
  testWidgets(
    'U78 · pendingResult ada → kartu hasil hadir di atas widget lain dalam '
    'urutan pohon',
    (tester) async {
      await tester.pumpWidget(
        bungkus(
          Column(
            children: [
              ChallengeResultCard(
                week: week(),
                rangeLabel: '17–23 Agu',
                line: 'Baris hasil.',
                onDismiss: () {},
              ),
              Container(key: const Key('kartu-utama-palsu'), height: 50),
            ],
          ),
        ),
      );

      expect(find.byType(ChallengeResultCard), findsOneWidget);
      final resultDy = tester.getTopLeft(find.byType(ChallengeResultCard)).dy;
      final mainDy = tester
          .getTopLeft(find.byKey(const Key('kartu-utama-palsu')))
          .dy;
      expect(resultDy, lessThan(mainDy));
    },
  );

  // ── U79 · tekan ✕ → onDismiss terpanggil TEPAT SEKALI ───────────────────
  testWidgets('U79 · tekan tombol tutup → onDismiss terpanggil tepat sekali', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(kartu(onDismiss: () => count++));
    await tester.tap(
      find.byKey(const Key('challenge-result-dismiss-button')),
    );
    await tester.pump();
    expect(count, 1);
  });

  // ── U80 · status held/skipped sebagai pendingResult → tidak dirender ────
  group('U80 · status non-achieved/missed → kartu hasil tidak dirender', () {
    testWidgets('status held → kosong', (tester) async {
      await tester.pumpWidget(kartu(w: week(status: ChallengeStatus.held)));
      expect(find.byKey(const Key('challenge-result-card')), findsNothing);
      expect(
        find.byKey(const Key('challenge-result-dismiss-button')),
        findsNothing,
      );
    });

    testWidgets('status skipped → kosong', (tester) async {
      await tester.pumpWidget(
        kartu(w: week(status: ChallengeStatus.skipped)),
      );
      expect(find.byKey(const Key('challenge-result-card')), findsNothing);
      expect(
        find.byKey(const Key('challenge-result-dismiss-button')),
        findsNothing,
      );
    });

    testWidgets('status active → kosong', (tester) async {
      await tester.pumpWidget(kartu(w: week(status: ChallengeStatus.active)));
      expect(find.byKey(const Key('challenge-result-card')), findsNothing);
    });

    testWidgets('status unknown → kosong', (tester) async {
      await tester.pumpWidget(
        kartu(w: week(status: ChallengeStatus.unknown)),
      );
      expect(find.byKey(const Key('challenge-result-card')), findsNothing);
    });
  });

  // ── U81 · tiga minggu hasil belum dilihat → satu kartu, weekKey terbesar
  testWidgets(
    'U81 · dari tiga kandidat, pemanggil menyerahkan satu week (weekKey '
    'terbesar) → widget merender persis yang diberikan',
    (tester) async {
      final a = week(weekKey: 20260810, status: ChallengeStatus.achieved);
      final b = week(weekKey: 20260817, status: ChallengeStatus.missed);
      final c = week(weekKey: 20260824, status: ChallengeStatus.achieved);
      final kandidat = [a, b, c];
      // Pemilihan weekKey TERBESAR adalah tanggung jawab ChallengeBloc
      // (Task 13, `_hasilBelumDilihatTerbaru`, dikunci U115b) — dua sisanya
      // sudah ditandai `resultSeenAt` oleh langkah 1c (Task 10). Test ini
      // mengunci kontrak PEMANGGIL: begitu satu week terpilih, widget
      // merender PERSIS satu kartu untuknya, tidak pernah menduplikasi
      // atau ikut merender kandidat lain.
      final terpilih = kandidat.reduce(
        (x, y) => x.weekKey > y.weekKey ? x : y,
      );
      expect(terpilih.weekKey, 20260824);

      await tester.pumpWidget(
        kartu(w: terpilih, line: 'Baris unik minggu 24 Agustus'),
      );

      expect(find.byType(ChallengeResultCard), findsOneWidget);
      expect(find.text('Baris unik minggu 24 Agustus'), findsOneWidget);
    },
  );

  // ── U82 · phase disabled DAN pendingResult ada → keduanya tampil ────────
  testWidgets(
    'U82 · phase disabled + pendingResult ada → keduanya tampil, kartu '
    'hasil di atas',
    (tester) async {
      await tester.pumpWidget(
        bungkus(
          Column(
            children: [
              ChallengeResultCard(
                week: week(),
                rangeLabel: '17–23 Agu',
                line: 'Baris hasil U82.',
                onDismiss: () {},
              ),
              const ChallengeEmptyCard(phase: PhaseDisabled()),
            ],
          ),
        ),
      );

      expect(find.byType(ChallengeResultCard), findsOneWidget);
      expect(find.text('Baris hasil U82.'), findsOneWidget);
      expect(find.byType(ChallengeEmptyCard), findsOneWidget);
      expect(find.text(l10n.challengeEmptyDisabledTitle), findsOneWidget);

      final resultDy = tester.getTopLeft(find.byType(ChallengeResultCard)).dy;
      final emptyDy = tester.getTopLeft(find.byType(ChallengeEmptyCard)).dy;
      expect(resultDy, lessThan(emptyDy));
    },
  );

  // ── U92 · tombol ✕ ukuran ≥48dp ──────────────────────────────────────────
  testWidgets('U92 · tombol tutup ukuran ≥48dp', (tester) async {
    await tester.pumpWidget(kartu());
    final size = tester.getSize(
      find.byKey(const Key('challenge-result-dismiss-button')),
    );
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  // ── Warna · seluruh Text/Icon pakai textSoft*, bukan fungsional ─────────
  group('Warna · teks & ikon kartu hasil pakai textSoft*', () {
    testWidgets('tema terang · eyebrow textSoftLight', (tester) async {
      await tester.pumpWidget(kartu());
      final t = tester.widget<Text>(
        find.byKey(const Key('challenge-result-eyebrow')),
      );
      expect(t.style?.color, AppColors.textSoftLight);
    });

    testWidgets('tema gelap · eyebrow textSoftDark', (tester) async {
      await tester.pumpWidget(kartu(isDark: true));
      final t = tester.widget<Text>(
        find.byKey(const Key('challenge-result-eyebrow')),
      );
      expect(t.style?.color, AppColors.textSoftDark);
    });

    testWidgets('tema terang · line textSoftLight', (tester) async {
      await tester.pumpWidget(kartu());
      final t = tester.widget<Text>(
        find.byKey(const Key('challenge-result-line')),
      );
      expect(t.style?.color, AppColors.textSoftLight);
    });

    testWidgets('tema gelap · line textSoftDark', (tester) async {
      await tester.pumpWidget(kartu(isDark: true));
      final t = tester.widget<Text>(
        find.byKey(const Key('challenge-result-line')),
      );
      expect(t.style?.color, AppColors.textSoftDark);
    });

    testWidgets('tema terang · ikon utama textSoftLight', (tester) async {
      await tester.pumpWidget(kartu());
      final icon = tester.widget<Icon>(
        find.byKey(const Key('challenge-result-icon')),
      );
      expect(icon.color, AppColors.textSoftLight);
    });

    testWidgets('tema gelap · ikon utama textSoftDark', (tester) async {
      await tester.pumpWidget(kartu(isDark: true));
      final icon = tester.widget<Icon>(
        find.byKey(const Key('challenge-result-icon')),
      );
      expect(icon.color, AppColors.textSoftDark);
    });

    testWidgets('tema terang · ikon tutup textSoftLight', (tester) async {
      await tester.pumpWidget(kartu());
      final icon = tester.widget<Icon>(
        find.byKey(const Key('challenge-result-dismiss-icon')),
      );
      expect(icon.color, AppColors.textSoftLight);
    });

    testWidgets('tema gelap · ikon tutup textSoftDark', (tester) async {
      await tester.pumpWidget(kartu(isDark: true));
      final icon = tester.widget<Icon>(
        find.byKey(const Key('challenge-result-dismiss-icon')),
      );
      expect(icon.color, AppColors.textSoftDark);
    });

    testWidgets(
      'nol Text/Icon memakai warna fungsional (warn/caution/primaryBright/'
      'success)',
      (tester) async {
        await tester.pumpWidget(kartu());
        const terlarang = [
          AppColors.warn,
          AppColors.caution,
          AppColors.primaryBright,
          AppColors.success,
        ];
        for (final t in tester.widgetList<Text>(find.byType(Text))) {
          expect(
            terlarang,
            isNot(contains(t.style?.color)),
            reason: 'Text "${t.data}" memakai warna fungsional',
          );
        }
        for (final i in tester.widgetList<Icon>(find.byType(Icon))) {
          expect(
            terlarang,
            isNot(contains(i.color)),
            reason: 'Icon ${i.icon} memakai warna fungsional',
          );
        }
      },
    );
  });

  // ── Latar · surface*, BUKAN card* ───────────────────────────────────────
  group('Latar · surface*, bukan card*', () {
    testWidgets('tema terang → surfaceLight', (tester) async {
      await tester.pumpWidget(kartu());
      final container = tester.widget<Container>(
        find.byKey(const Key('challenge-result-card')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.surfaceLight);
      expect(decoration.color, isNot(AppColors.cardLight));
    });

    testWidgets('tema gelap → surfaceDark', (tester) async {
      await tester.pumpWidget(kartu(isDark: true));
      final container = tester.widget<Container>(
        find.byKey(const Key('challenge-result-card')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.surfaceDark);
      expect(decoration.color, isNot(AppColors.cardDark));
    });
  });

  // ── S-C · pohon widget tidak mengimpor app_database.dart ────────────────
  test(
    'S-C · challenge_result_card.dart dan challenge_empty_card.dart tidak '
    'mengimpor app_database.dart',
    () async {
      final result = await Process.run('grep', [
        '-F',
        '-l',
        'app_database.dart',
        'lib/features/challenge/presentation/widgets/challenge_result_card.dart',
        'lib/features/challenge/presentation/widgets/challenge_empty_card.dart',
      ]);
      expect(
        result.exitCode,
        1,
        reason:
            'setidaknya satu file kartu hasil/kosong mengimpor '
            'app_database.dart. stdout: ${result.stdout}',
      );
    },
  );
}
