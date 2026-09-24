import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_bloc.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_event.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_state.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bento_banner_tile.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bento_feat_tile.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/challenge_bento_tile.dart';

/// Task 17 — tile bento "Tantangan / Mingguan" di dashboard.
///
/// Tile TIDAK menghitung keadaannya sendiri (S1) — ia hanya `switch` pada
/// `ChallengeSnapshot.phase` yang sudah dirakit `ChallengeBloc`, persis pola
/// `ConsistencyBentoTile` (Task 16) meniru `StreakBloc`.
///
/// Sepuluh varian [ChallengePhase] memetakan ke SEMBILAN hasil render:
/// `PhaseSettledThisWeek` dan `PhaseOutOfWindow` SENGAJA memakai teks yang
/// sama ("Mulai Senin depan") — dartdoc `challenge_phase.dart:61-62`
/// menyatakan keduanya "berkata sama ke user". `PhaseUndetermined` dan
/// `PhasePreparing` merender skeleton, bukan teks.
class MockChallengeBloc extends MockBloc<ChallengeEvent, ChallengeState>
    implements ChallengeBloc {}

// Delegate sinkron — rootBundle async bentrok dengan pumpWidget tanpa
// pumpAndSettle (pola sama seperti consistency_bento_tile_test.dart).
class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._l10n);
  final AppLocalizations _l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _l10n;

  @override
  bool shouldReload(covariant _SyncL10nDelegate old) => true;
}

void main() {
  late AppLocalizations l10nId;
  late AppLocalizations l10nEn;
  late MockChallengeBloc bloc;

  setUpAll(() async {
    l10nId = await AppLocalizations.delegate.load(const Locale('id'));
    l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    bloc = MockChallengeBloc();
  });

  void stub(ChallengeState state) {
    whenListen(bloc, Stream<ChallengeState>.value(state), initialState: state);
  }

  ChallengeState buildState(ChallengePhase? phase) => ChallengeState(
    status: phase == null
        ? ChallengeViewStatus.loading
        : ChallengeViewStatus.ready,
    snapshot: phase == null
        ? null
        : ChallengeSnapshot(
            phase: phase,
            pendingResult: null,
            spentThisWeek: 0,
            excludedThisWeek: 0,
            history: const [],
            daysLeft: 5,
          ),
  );

  ChallengeWeek buildWeek({
    required ChallengeStatus status,
    String? category = 'food',
    int? target = 100000,
  }) => ChallengeWeek(
    weekKey: 20260921,
    category: category,
    targetAmount: target,
    baselineAmount: 120000,
    status: status,
    finalSpent: null,
    resolvedAt: null,
    resultSeenAt: null,
  );

  // Router dua-rute minimal: '/' merender dashboard palsu + tile, '/challenge'
  // merender penanda — persis pola consistency_bento_tile_test.dart.
  GoRouter buildTestRouter() => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('DASHBOARD_PAGE_MARKER'),
              BlocProvider<ChallengeBloc>.value(
                value: bloc,
                child: const ChallengeBentoTile(),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/challenge',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (innerContext) => Text(
              'CHALLENGE_PAGE_MARKER canPop='
              '${Navigator.of(innerContext).canPop()}',
            ),
          ),
        ),
      ),
    ],
  );

  Widget harness({AppLocalizations? l10n, ThemeData? theme}) {
    final active = l10n ?? l10nId;
    return MaterialApp.router(
      routerConfig: buildTestRouter(),
      locale: Locale(active.locale.languageCode),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: [
        _SyncL10nDelegate(active),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme,
    );
  }

  // ── U96 — kesepuluh varian phase, sesuai tabel spec baris 1416-1426 ──
  group('U96 · sepuluh varian phase merender sesuai tabel spec', () {
    testWidgets('disabled → "Coba tantangan hemat?"', (tester) async {
      stub(buildState(const PhaseDisabled()));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text(l10nId.challengeTileOff), findsOneWidget);
    });

    testWidgets('active → "{category} · sisa {amount}"', (tester) async {
      final week = buildWeek(status: ChallengeStatus.active);
      stub(buildState(PhaseActive(week: week, spent: 66000)));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(
        find.text(l10nId.challengeTileActive('Makan & Minum', 'Rp 34.000')),
        findsOneWidget,
      );
    });

    testWidgets('over → "{category} · lewat {amount}", BUKAN "sisa"', (
      tester,
    ) async {
      final week = buildWeek(status: ChallengeStatus.active);
      stub(buildState(PhaseOver(week: week, spent: 112000)));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(
        find.text(l10nId.challengeTileOver('Makan & Minum', 'Rp 12.000')),
        findsOneWidget,
      );
      expect(
        find.text(l10nId.challengeTileActive('Makan & Minum', 'Rp 12.000')),
        findsNothing,
      );
    });

    testWidgets('held → "Fokus bertahan dulu"', (tester) async {
      final week = buildWeek(status: ChallengeStatus.held, category: null);
      stub(buildState(PhaseHeld(week)));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text(l10nId.challengeTileHeld), findsOneWidget);
    });

    testWidgets('settledThisWeek → "Mulai Senin depan"', (tester) async {
      final week = buildWeek(status: ChallengeStatus.achieved);
      stub(buildState(PhaseSettledThisWeek(week)));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text(l10nId.challengeTileWindow), findsOneWidget);
    });

    testWidgets(
      'outOfWindow → "Mulai Senin depan" — SAMA dengan settledThisWeek '
      '(disengaja, bukan bug)',
      (tester) async {
        stub(buildState(const PhaseOutOfWindow(isFirstWeek: false)));
        await tester.pumpWidget(harness());
        await tester.pump();
        expect(find.text(l10nId.challengeTileWindow), findsOneWidget);
      },
    );

    testWidgets('outOfWindow minggu pertama → teks tetap sama juga', (
      tester,
    ) async {
      stub(buildState(const PhaseOutOfWindow(isFirstWeek: true)));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text(l10nId.challengeTileWindow), findsOneWidget);
    });

    testWidgets('notEnoughData → "Belum cukup data"', (tester) async {
      stub(buildState(const PhaseNotEnoughData()));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text(l10nId.challengeTileNoData), findsOneWidget);
    });

    testWidgets('budgetNotSet → "Atur anggaran dulu"', (tester) async {
      stub(buildState(const PhaseBudgetNotSet()));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text(l10nId.challengeTileBudget), findsOneWidget);
    });

    testWidgets('undetermined → skeleton, BUKAN teks', (tester) async {
      stub(buildState(const PhaseUndetermined()));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.byKey(const Key('challenge-bento-skeleton')), findsOneWidget);
      expect(find.byType(BentoBannerTile), findsNothing);
    });

    testWidgets('preparing → skeleton, BUKAN teks', (tester) async {
      stub(buildState(const PhasePreparing()));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.byKey(const Key('challenge-bento-skeleton')), findsOneWidget);
      expect(find.byType(BentoBannerTile), findsNothing);
    });

    testWidgets('belum ada snapshot sama sekali → skeleton juga', (
      tester,
    ) async {
      stub(buildState(null));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.byKey(const Key('challenge-bento-skeleton')), findsOneWidget);
    });
  });

  // ── U119 — D24: tile SELALU hijau, phase over dibedakan lewat kata ──
  group('butir 4 · tile selebar penuh berbentuk banner', () {
    testWidgets('phase siap → BentoBannerTile, BUKAN BentoFeatTile vertikal', (
      tester,
    ) async {
      stub(buildState(const PhaseDisabled()));
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.byType(BentoBannerTile), findsOneWidget);
      expect(find.byType(BentoFeatTile), findsNothing);
    });

    testWidgets(
      'skeleton berbentuk banner juga — tak melompat saat data tiba',
      (tester) async {
        stub(buildState(null));
        await tester.pumpWidget(harness());
        await tester.pump();
        final tinggi = tester
            .getSize(find.byKey(const Key('challenge-bento-skeleton')))
            .height;
        expect(tinggi, kBentoBannerMinHeight);
      },
    );
  });

  group('U119 · bg tile SELALU AppColors.primary, phase over bukan warn', () {
    testWidgets('phase over → bg primary, BUKAN warn', (tester) async {
      final week = buildWeek(status: ChallengeStatus.active);
      stub(buildState(PhaseOver(week: week, spent: 112000)));
      await tester.pumpWidget(harness());
      await tester.pump();

      final tile = tester.widget<BentoBannerTile>(find.byType(BentoBannerTile));
      expect(tile.bg, AppColors.primary);
      expect(tile.bg, isNot(AppColors.warn));
    });

    testWidgets('phase active dan over → bg keduanya SAMA', (tester) async {
      final week = buildWeek(status: ChallengeStatus.active);

      stub(buildState(PhaseActive(week: week, spent: 66000)));
      await tester.pumpWidget(harness());
      await tester.pump();
      final bgActive = tester
          .widget<BentoBannerTile>(find.byType(BentoBannerTile))
          .bg;

      bloc = MockChallengeBloc();
      stub(buildState(PhaseOver(week: week, spent: 112000)));
      await tester.pumpWidget(harness());
      await tester.pump();
      final bgOver = tester
          .widget<BentoBannerTile>(find.byType(BentoBannerTile))
          .bg;

      expect(bgActive, bgOver);
      expect(bgActive, AppColors.primary);
    });
  });

  // ── U97 — phase dari resolveChallengePhase == phase dari BLoC ──
  group('U97 · phase yang dipakai tile identik dengan resolveChallengePhase — '
      'tile tidak menghitung sendiri', () {
    testWidgets('input mentah "sakelar mati" → phase disabled', (tester) async {
      final phase = resolveChallengePhase(
        weekThisWeek: null,
        spentThisWeek: 0,
        enabled: false,
        env: null,
        candidateCount: null,
        historyEmpty: true,
        localNow: DateTime(2026, 9, 21),
      );
      expect(phase, const PhaseDisabled());

      stub(buildState(phase));
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.text(l10nId.challengeTileOff), findsOneWidget);
    });

    testWidgets('input mentah "belanja lewat target" → phase over, tile setuju '
        'persis', (tester) async {
      final week = buildWeek(status: ChallengeStatus.active);
      final phase = resolveChallengePhase(
        weekThisWeek: week,
        spentThisWeek: 112000,
        enabled: true,
        env: null,
        candidateCount: null,
        historyEmpty: false,
        localNow: DateTime(2026, 9, 21),
      );
      expect(phase, isA<PhaseOver>());

      stub(buildState(phase));
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(
        find.text(l10nId.challengeTileOver('Makan & Minum', 'Rp 12.000')),
        findsOneWidget,
      );
    });
  });

  // ── U94 — nol literal Indonesia, semua teks lewat context.l10n ──
  group('U94 · nol literal Indonesia — render EN, semua teks via l10n', () {
    testWidgets('phase disabled di locale EN → teks EN, bukan ID', (
      tester,
    ) async {
      stub(buildState(const PhaseDisabled()));
      await tester.pumpWidget(harness(l10n: l10nEn));
      await tester.pump();

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ChallengeBentoTile),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toSet();

      expect(texts, {
        l10nEn.dashboardBentoChallengeLabel,
        l10nEn.challengeTileOff,
        l10nEn.dashboardBentoChallengeSub,
      });
      expect(texts.contains(l10nId.challengeTileOff), isFalse);
      expect(texts.contains(l10nId.dashboardBentoChallengeLabel), isFalse);
      expect(texts.contains(l10nId.dashboardBentoChallengeSub), isFalse);
    });

    testWidgets('phase active di locale EN → kategori & sub ikut EN', (
      tester,
    ) async {
      final week = buildWeek(status: ChallengeStatus.active);
      stub(buildState(PhaseActive(week: week, spent: 66000)));
      await tester.pumpWidget(harness(l10n: l10nEn));
      await tester.pump();

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ChallengeBentoTile),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toSet();

      expect(texts, {
        l10nEn.dashboardBentoChallengeLabel,
        l10nEn.challengeTileActive('Food & Drinks', 'Rp 34.000'),
        l10nEn.dashboardBentoChallengeSub,
      });
      expect(
        texts.contains(
          l10nId.challengeTileActive('Makan & Minum', 'Rp 34.000'),
        ),
        isFalse,
      );
    });

    testWidgets('skeleton (undetermined) → nol Text widget sama sekali', (
      tester,
    ) async {
      stub(buildState(const PhaseUndetermined()));
      await tester.pumpWidget(harness(l10n: l10nEn));
      await tester.pump();

      final texts = tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(const Key('challenge-bento-skeleton')),
          matching: find.byType(Text),
        ),
      );
      expect(texts, isEmpty);
    });
  });

  // ── Navigasi & tema ──
  testWidgets(
    'tap membuka /challenge lewat push (dashboard tetap di tumpukan)',
    (tester) async {
      stub(buildState(const PhaseDisabled()));
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.textContaining('CHALLENGE_PAGE_MARKER'), findsNothing);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('CHALLENGE_PAGE_MARKER canPop=true'), findsOneWidget);
    },
  );

  testWidgets('dark mode render tanpa error', (tester) async {
    final week = buildWeek(status: ChallengeStatus.active);
    stub(buildState(PhaseActive(week: week, spent: 66000)));
    await tester.pumpWidget(harness(theme: ThemeData.dark()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
