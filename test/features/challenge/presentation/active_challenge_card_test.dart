// Task 14 — bar progres dan kartu utama tantangan (aktif / lewat target).
//
// Aturan visual mengikat (spec §7) yang test ini kunci:
// - Teks sekunder DI DALAM kartu selalu `textSoft*`, tidak pernah `muted*`.
// - Nominal "lewat target" selalu `text*`, TIDAK PERNAH `warn`.
// - Ketiga ambang bar WAJIB membawa kata + ikon (color-not-only).
// - Track bar diberi outline 1px `muted*`.
// - Baris pengecualian tagihan hanya muncul bila `excludedSpent > 0`.
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
import 'package:penyintas_app/features/challenge/presentation/widgets/active_challenge_card.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_progress_bar.dart';

/// Delegate sinkron — `rootBundle` bisa hang di test ke-2+ bila l10n dimuat
/// async per-pump. Preload sekali di setUpAll (pola dari pin_keypad_test.dart).
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
    int weekKey = 20260601,
    String? category = 'food',
    int? target = 100000,
    int? baseline = 130000,
  }) => ChallengeWeek(
    weekKey: weekKey,
    category: category,
    targetAmount: target,
    baselineAmount: baseline,
    status: ChallengeStatus.active,
    finalSpent: null,
    resolvedAt: null,
    resultSeenAt: null,
  );

  Widget bungkus(
    Widget child, {
    bool isDark = false,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    locale: const Locale('id'),
    localizationsDelegates: [_SyncL10nDelegate(l10n)],
    theme: ThemeData(brightness: Brightness.light),
    darkTheme: ThemeData(brightness: Brightness.dark),
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );

  Widget kartu({
    int spent = 30000,
    int target = 100000,
    bool isOver = false,
    int excludedSpent = 0,
    int daysLeft = 3,
    bool showChangeCategory = true,
    bool isDark = false,
    TextScaler textScaler = TextScaler.noScaling,
    VoidCallback? onChangeCategory,
    String? category = 'food',
  }) {
    final w = week(target: target, category: category);
    final phase = isOver
        ? PhaseOver(week: w, spent: spent)
        : PhaseActive(week: w, spent: spent);
    return bungkus(
      ActiveChallengeCard(
        phase: phase,
        excludedSpent: excludedSpent,
        daysLeft: daysLeft,
        showChangeCategory: showChangeCategory,
        onChangeCategory: onChangeCategory ?? () {},
      ),
      isDark: isDark,
      textScaler: textScaler,
    );
  }

  // ── U86 · teks sekunder tidak pernah muted* ─────────────────────────────
  group('U86 · nol Text memakai muted*', () {
    testWidgets('tema terang — nol Text pakai mutedLight', (tester) async {
      await tester.pumpWidget(
        kartu(spent: 85000, target: 100000, excludedSpent: 20000),
      );
      final texts = tester.widgetList<Text>(find.byType(Text));
      for (final t in texts) {
        expect(
          t.style?.color,
          isNot(AppColors.mutedLight),
          reason: 'Text "${t.data}" memakai mutedLight',
        );
      }
    });

    testWidgets('tema gelap — nol Text pakai mutedDark', (tester) async {
      await tester.pumpWidget(
        kartu(spent: 85000, target: 100000, excludedSpent: 20000, isDark: true),
      );
      final texts = tester.widgetList<Text>(find.byType(Text));
      for (final t in texts) {
        expect(
          t.style?.color,
          isNot(AppColors.mutedDark),
          reason: 'Text "${t.data}" memakai mutedDark',
        );
      }
    });
  });

  // ── U87 · nominal lewat target pakai text*, bukan warn ──────────────────
  group('U87 · nominal over pakai text*', () {
    testWidgets('tema terang → textLight', (tester) async {
      await tester.pumpWidget(
        kartu(spent: 130000, target: 100000, isOver: true),
      );
      final nominal = tester.widget<Text>(find.text('Rp 30.000'));
      expect(nominal.style?.color, AppColors.textLight);
    });

    testWidgets('tema gelap → textDark', (tester) async {
      await tester.pumpWidget(
        kartu(spent: 130000, target: 100000, isOver: true, isDark: true),
      );
      final nominal = tester.widget<Text>(find.text('Rp 30.000'));
      expect(nominal.style?.color, AppColors.textDark);
    });
  });

  // ── U88 · ketiga ambang bawa kata + ikon ────────────────────────────────
  group('U88 · ambang 40/65/95% bawa kata + ikon', () {
    testWidgets('40% (aman) → Icon eco_outlined tampil', (tester) async {
      await tester.pumpWidget(kartu(spent: 40000, target: 100000));
      expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
    });

    testWidgets('40% (aman) → label "Aman" tampil', (tester) async {
      await tester.pumpWidget(kartu(spent: 40000, target: 100000));
      expect(find.text(l10n.challengeBarStateSafe), findsOneWidget);
    });

    testWidgets('65% (mendekati) → Icon bolt_outlined tampil', (tester) async {
      await tester.pumpWidget(kartu(spent: 65000, target: 100000));
      expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
    });

    testWidgets('65% (mendekati) → label "Mendekati batas" tampil', (
      tester,
    ) async {
      await tester.pumpWidget(kartu(spent: 65000, target: 100000));
      expect(find.text(l10n.challengeBarStateCaution), findsOneWidget);
    });

    testWidgets('95% (lewat ambang, masih aktif) → Icon warning tampil', (
      tester,
    ) async {
      await tester.pumpWidget(kartu(spent: 95000, target: 100000));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('95% (lewat ambang, masih aktif) → label "Lewat target"', (
      tester,
    ) async {
      await tester.pumpWidget(kartu(spent: 95000, target: 100000));
      expect(find.text(l10n.challengeBarStateOver), findsOneWidget);
    });
  });

  // ── U89 · isi bar ambang aman ────────────────────────────────────────────
  group('U89 · isi bar ambang aman', () {
    testWidgets('tema gelap → primaryBright', (tester) async {
      await tester.pumpWidget(
        bungkus(
          const ChallengeProgressBar(
            spent: 30000,
            target: 100000,
            isDark: true,
          ),
          isDark: true,
        ),
      );
      final fill = tester.widget<Container>(
        find.byKey(const Key('challenge-bar-fill')),
      );
      final dec = fill.decoration! as BoxDecoration;
      expect(dec.color, AppColors.primaryBright);
    });

    testWidgets('tema terang → primary (bukan primaryBright)', (tester) async {
      await tester.pumpWidget(
        bungkus(
          const ChallengeProgressBar(
            spent: 30000,
            target: 100000,
            isDark: false,
          ),
        ),
      );
      final fill = tester.widget<Container>(
        find.byKey(const Key('challenge-bar-fill')),
      );
      final dec = fill.decoration! as BoxDecoration;
      expect(dec.color, AppColors.primary);
    });
  });

  // ── U113 · track bar punya outline 1px muted ────────────────────────────
  group('U113 · track bar outline', () {
    testWidgets('border tidak null', (tester) async {
      await tester.pumpWidget(
        bungkus(
          const ChallengeProgressBar(
            spent: 30000,
            target: 100000,
            isDark: false,
          ),
        ),
      );
      final track = tester.widget<Container>(
        find.byKey(const Key('challenge-bar-track')),
      );
      final dec = track.decoration! as BoxDecoration;
      expect(dec.border, isNotNull);
    });

    testWidgets('warna border mutedLight (tema terang)', (tester) async {
      await tester.pumpWidget(
        bungkus(
          const ChallengeProgressBar(
            spent: 30000,
            target: 100000,
            isDark: false,
          ),
        ),
      );
      final track = tester.widget<Container>(
        find.byKey(const Key('challenge-bar-track')),
      );
      final dec = track.decoration! as BoxDecoration;
      expect((dec.border! as Border).top.color, AppColors.mutedLight);
    });

    testWidgets('lebar border 1', (tester) async {
      await tester.pumpWidget(
        bungkus(
          const ChallengeProgressBar(
            spent: 30000,
            target: 100000,
            isDark: false,
          ),
        ),
      );
      final track = tester.widget<Container>(
        find.byKey(const Key('challenge-bar-track')),
      );
      final dec = track.decoration! as BoxDecoration;
      expect((dec.border! as Border).top.width, 1);
    });
  });

  // ── U111 · baris pengecualian hanya saat excludedSpent > 0 ──────────────
  group('U111 · baris pengecualian', () {
    testWidgets('excludedSpent 186000 → teks hadir dengan angka 186.000', (
      tester,
    ) async {
      await tester.pumpWidget(kartu(excludedSpent: 186000));
      expect(find.textContaining('186.000'), findsOneWidget);
      expect(find.textContaining('tidak dihitung'), findsOneWidget);
    });

    testWidgets('excludedSpent 0 → teks tidak ada di pohon', (tester) async {
      await tester.pumpWidget(kartu(excludedSpent: 0));
      expect(find.textContaining('tidak dihitung'), findsNothing);
    });
  });

  // ── S-C · pohon widget tidak mengimpor app_database.dart ────────────────
  test('S-C · challenge_progress_bar.dart dan active_challenge_card.dart '
      'tidak mengimpor app_database.dart', () async {
    final result = await Process.run('grep', [
      '-F',
      '-l',
      'app_database.dart',
      'lib/features/challenge/presentation/widgets/challenge_progress_bar.dart',
      'lib/features/challenge/presentation/widgets/active_challenge_card.dart',
    ]);
    expect(
      result.exitCode,
      1,
      reason:
          'setidaknya satu file kartu/bar mengimpor app_database.dart. '
          'stdout: ${result.stdout}',
    );
  });

  // ── U92 · baris "Ganti pos" hit target ≥48dp ─────────────────────────────
  testWidgets('U92 · showChangeCategory true → tinggi baris ≥ 48', (
    tester,
  ) async {
    await tester.pumpWidget(kartu(showChangeCategory: true));
    final size = tester.getSize(
      find.byKey(const Key('challenge-change-category-row')),
    );
    expect(size.height, greaterThanOrEqualTo(48));
  });

  // ── U83 · showChangeCategory false → baris dihapus, bukan disabled ─────
  testWidgets('U83 · showChangeCategory false → baris Ganti pos tidak ada', (
    tester,
  ) async {
    await tester.pumpWidget(kartu(showChangeCategory: false));
    expect(
      find.byKey(const Key('challenge-change-category-row')),
      findsNothing,
    );
    expect(find.text(l10n.challengeCardChangeCategory), findsNothing);
  });

  // ── U93 · tepat satu Semantics memuat nominal, target, kategori, hari ──
  testWidgets(
    'U93 · tepat satu Semantics memuat nominal sisa, target, kategori, sisa hari',
    (tester) async {
      await tester.pumpWidget(
        kartu(
          spent: 30000,
          target: 100000,
          daysLeft: 4,
          category: 'food',
          isOver: false,
        ),
      );
      final categoryLabel = l10n.categoryFood;
      final nominalStr = 'Rp 70.000'; // 100.000 - 30.000
      final targetStr = '100.000';
      final daysStr = l10n.daysLeft(4);

      final matches = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) {
            final label = s.properties.label ?? '';
            return label.contains(categoryLabel) &&
                label.contains(nominalStr) &&
                label.contains(targetStr) &&
                label.contains(daysStr);
          });

      expect(matches, hasLength(1));
    },
  );

  // ── Gerbang UI tambahan ──────────────────────────────────────────────────
  group('Gerbang tambahan', () {
    testWidgets('dynamic-type · textScaler 2.0 → nol overflow', (tester) async {
      await tester.pumpWidget(
        kartu(
          spent: 130000,
          target: 100000,
          isOver: true,
          excludedSpent: 186000,
          showChangeCategory: true,
          textScaler: const TextScaler.linear(2.0),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'press-feedback · baris Ganti pos pakai InkWell, bukan GestureDetector telanjang',
      (tester) async {
        await tester.pumpWidget(kartu(showChangeCategory: true));
        final widget = tester.widget(
          find.byKey(const Key('challenge-change-category-row')),
        );
        expect(widget, isA<InkWell>());
      },
    );

    testWidgets('Ganti pos · tap memanggil onChangeCategory', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        kartu(showChangeCategory: true, onChangeCategory: () => tapped = true),
      );
      await tester.tap(find.byKey(const Key('challenge-change-category-row')));
      expect(tapped, isTrue);
    });
  });
}
