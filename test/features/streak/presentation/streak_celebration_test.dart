import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';
import 'package:penyintas_app/features/streak/presentation/pages/consistency_page.dart';
import 'package:penyintas_app/features/streak/presentation/widgets/streak_break_card.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';
import 'package:penyintas_app/widgets/common/milestone_toast.dart';

class MockStreakBloc extends MockBloc<StreakEvent, StreakState>
    implements StreakBloc {}

class MockSurvivalBloc extends MockBloc<SurvivalEvent, SurvivalState>
    implements SurvivalBloc {}

// Delegate sinkron — sama seperti `consistency_page_test.dart`, menghindari
// jeda async `rootBundle` di dalam `pumpWidget`.
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

/// Task 14 — dua aturan yang gampang salah dan langsung terasa user:
///
/// 1. **Kartu ruas terhenti** (§8.5). Pengakuan, bukan peringatan: token
///    `card*`, bukan `warn`; menyebut panjang ruas yang DICAPAI, bukan nol.
/// 2. **Urutan perayaan terhadap SnackBar undo** (§7.5).
///    `MilestoneToast.show()` memanggil `hideCurrentSnackBar()`
///    (`milestone_toast.dart:41`) — merayakan terlalu cepat MEMBUNUH tombol
///    "Urungkan" sebelum user sempat melihatnya.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
    // `StreakEvent` sealed DAN tanpa Equatable: dua instance tak pernah sama,
    // jadi fallback-nya event sungguhan dan verifikasinya memakai matcher
    // TIPE, bukan kesetaraan nilai.
    registerFallbackValue(StreakRefreshed());
  });

  StreakSnapshot buildSnapshot({
    bool hasStarted = true,
    int streak = 12,
    int longestRuas = 40,
    int graceAvailable = 2,
    DayStatus todayStatus = DayStatus.pending,
    int today = 20260905,
    int activatedDay = 20260101,
    Set<int> markedDaysAll = const {},
    int? lastBreakDay,
    int brokenRunLength = 0,
  }) => StreakSnapshot(
    hasStarted: hasStarted,
    activatedDay: activatedDay,
    currentStreak: streak,
    longestRuas: longestRuas,
    graceAvailable: graceAvailable,
    graceUsedDays: const {},
    todayStatus: todayStatus,
    today: today,
    nextLastSeenDay: today,
    lastBreakDay: lastBreakDay,
    brokenRunLength: brokenRunLength,
    markedDays: const {},
    markedDaysAll: markedDaysAll,
    transactionDays: const {},
    clockAnomalyDetected: false,
  );

  StreakState buildState({
    StreakStatus status = StreakStatus.ready,
    StreakSnapshot? snapshot,
    bool isMarking = false,
    int? pendingCelebration,
    int? unacknowledgedBreakRun,
  }) => StreakState(
    status: status,
    snapshot: snapshot,
    isMarking: isMarking,
    pendingCelebration: pendingCelebration,
    unacknowledgedBreakRun: unacknowledgedBreakRun,
  );

  Widget bungkus({
    required StreakBloc streakBloc,
    required SurvivalBloc survivalBloc,
    Brightness brightness = Brightness.light,
  }) => MaterialApp(
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    theme: ThemeData(brightness: brightness),
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: MultiBlocProvider(
      providers: [
        BlocProvider<StreakBloc>.value(value: streakBloc),
        BlocProvider<SurvivalBloc>.value(value: survivalBloc),
      ],
      child: const ConsistencyPage(),
    ),
  );

  Widget harness({
    required StreakState state,
    Brightness brightness = Brightness.light,
  }) {
    final streakBloc = MockStreakBloc();
    whenListen(
      streakBloc,
      Stream<StreakState>.value(state),
      initialState: state,
    );
    final survivalBloc = MockSurvivalBloc();
    whenListen(
      survivalBloc,
      Stream<SurvivalState>.value(const SurvivalInactive()),
      initialState: const SurvivalInactive(),
    );
    return bungkus(
      streakBloc: streakBloc,
      survivalBloc: survivalBloc,
      brightness: brightness,
    );
  }

  /// Varian untuk `BlocListener`: `listenWhen` membandingkan state SEBELUM
  /// dan SESUDAH, jadi ia menuntut TRANSISI — satu state tunggal tidak pernah
  /// memicunya. Bloc diserahkan pemanggil supaya event yang di-add BALIK oleh
  /// tombol bisa diverifikasi.
  Widget harnessTransisi(
    MockStreakBloc streakBloc,
    Stream<StreakState> aliran,
    StreakState awal,
  ) {
    whenListen(streakBloc, aliran, initialState: awal);
    final survivalBloc = MockSurvivalBloc();
    whenListen(
      survivalBloc,
      Stream<SurvivalState>.value(const SurvivalInactive()),
      initialState: const SurvivalInactive(),
    );
    return bungkus(streakBloc: streakBloc, survivalBloc: survivalBloc);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // T22 — kartu ruas terhenti (§8.5)
  // ─────────────────────────────────────────────────────────────────────────

  group('T22 — kartu ruas terhenti', () {
    StreakState putus({int run = 40, int streak = 0}) => buildState(
      snapshot: buildSnapshot(
        streak: streak,
        lastBreakDay: 20260904,
        brokenRunLength: run,
      ),
      unacknowledgedBreakRun: run,
    );

    testWidgets(
      'T22: kartu tampil sekali dan menyebut panjang ruas 40, BUKAN angka nol',
      (tester) async {
        await tester.pumpWidget(harness(state: putus()));
        await tester.pump();

        expect(find.byType(StreakBreakCard), findsOneWidget);
        expect(find.text('Ruas ini terhenti di 40 hari.'), findsOneWidget);
        expect(
          find.text('Rekormu tetap tersimpan. Mulai ruas baru hari ini.'),
          findsOneWidget,
        );
        // §8.5 ada justru karena user 40 hari membuka app dan disambut "0".
        expect(find.text('0'), findsNothing);
      },
    );

    testWidgets(
      'T22: menekan "Oke" mengirim StreakBreakAcknowledged dan kartunya '
      'tidak muncul lagi',
      (tester) async {
        final bloc = MockStreakBloc();
        final kanal = StreamController<StreakState>.broadcast();
        addTearDown(kanal.close);

        await tester.pumpWidget(harnessTransisi(bloc, kanal.stream, putus()));
        await tester.pump();
        expect(find.byType(StreakBreakCard), findsOneWidget);

        await tester.tap(find.byKey(const Key('consistency-break-ok')));
        await tester.pump();

        verify(
          () => bloc.add(any(that: isA<StreakBreakAcknowledged>())),
        ).called(1);

        // Bloc sesungguhnya membalas dengan `clearBreak: true`.
        kanal.add(
          buildState(
            snapshot: buildSnapshot(streak: 0, lastBreakDay: 20260904),
          ),
        );
        await tester.pump();

        expect(find.byType(StreakBreakCard), findsNothing);
      },
    );

    testWidgets('kartu putus memakai token card, BUKAN warn — ini pengakuan, '
        'bukan peringatan', (tester) async {
      BoxDecoration dekorasiKartu() =>
          tester
                  .widget<Container>(
                    find.byKey(const Key('consistency-break-surface')),
                  )
                  .decoration!
              as BoxDecoration;

      await tester.pumpWidget(harness(state: putus()));
      await tester.pumpAndSettle();
      expect(dekorasiKartu().color, isNot(AppColors.warn));
      expect(dekorasiKartu().color, AppColors.cardLight);

      // `pumpAndSettle`, bukan `pump`: `MaterialApp` menyisipkan
      // `AnimatedTheme`, jadi satu frame saja masih menyajikan tema LAMA
      // dan asersi gelap di bawah akan membaca warna terang.
      await tester.pumpWidget(
        harness(state: putus(), brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();
      expect(dekorasiKartu().color, isNot(AppColors.warn));
      expect(dekorasiKartu().color, AppColors.cardDark);
    });

    testWidgets('tombol "Oke" memenuhi ambang sentuh 48dp', (tester) async {
      await tester.pumpWidget(harness(state: putus()));
      await tester.pump();

      expect(
        tester.getSize(find.byKey(const Key('consistency-break-ok'))).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Urutan perayaan terhadap SnackBar undo (§7.5)
  // ─────────────────────────────────────────────────────────────────────────

  group('Urutan perayaan terhadap SnackBar undo', () {
    /// Transisi `isMarking: true -> false` adalah yang dibandingkan
    /// `listenWhen` SnackBar di halaman.
    StreakState sedangMenandai() =>
        buildState(snapshot: buildSnapshot(), isMarking: true);

    /// Emisi yang membawa DUA hal sekaligus: penandaan selesai (SnackBar
    /// undo) dan ruas 3 tercapai (perayaan). Persis jalur tabrakan §7.5.
    StreakState selesaiDanRuasTercapai() => buildState(
      snapshot: buildSnapshot(todayStatus: DayStatus.safe, streak: 3),
      pendingCelebration: 3,
    );

    /// Mendorong emisi di atas dan menuntaskan animasi MASUK SnackBar.
    /// Tanpa `pump()` pertama, `StreamController.broadcast()` membuang event
    /// karena halaman belum ter-mount (delegate l10n `load()` async menahan
    /// subtree satu frame).
    Future<void> tandaiSampaiSnackBarTampil(
      WidgetTester tester,
      StreamController<StreakState> kanal,
    ) async {
      await tester.pump();
      kanal.add(selesaiDanRuasTercapai());
      await tester.pump();
      // Timer auto-dismiss baru dipasang sesudah SnackBar benar-benar
      // terlihat, jadi tanpa ini penundaan di bawah menghitung dari titik
      // yang salah — dan tombolnya masih di luar viewport 800x600.
      await tester.pumpAndSettle();
    }

    testWidgets('perayaan TIDAK muncul selagi SnackBar undo masih hidup', (
      tester,
    ) async {
      final bloc = MockStreakBloc();
      final kanal = StreamController<StreakState>.broadcast();
      addTearDown(kanal.close);

      await tester.pumpWidget(
        harnessTransisi(bloc, kanal.stream, sedangMenandai()),
      );
      await tandaiSampaiSnackBarTampil(tester, kanal);
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MilestoneToast), findsNothing);
      expect(find.text('Urungkan'), findsOneWidget);
    });

    testWidgets('perayaan muncul sesudah SnackBar undo tertutup', (
      tester,
    ) async {
      final bloc = MockStreakBloc();
      final kanal = StreamController<StreakState>.broadcast();
      addTearDown(kanal.close);

      await tester.pumpWidget(
        harnessTransisi(bloc, kanal.stream, sedangMenandai()),
      );
      await tandaiSampaiSnackBarTampil(tester, kanal);

      // SnackBar undo berdurasi 5 detik; lewati lalu tuntaskan animasi
      // keluarnya supaya `.closed` benar-benar selesai.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(find.byType(MilestoneToast), findsOneWidget);
      expect(
        find.text('Satu ruas dilalui. Lanjut ke ruas berikutnya.'),
        findsOneWidget,
      );
    });

    testWidgets('perayaan BATAL bila user menekan Urungkan', (tester) async {
      final bloc = MockStreakBloc();
      final kanal = StreamController<StreakState>.broadcast();
      addTearDown(kanal.close);

      await tester.pumpWidget(
        harnessTransisi(bloc, kanal.stream, sedangMenandai()),
      );
      await tandaiSampaiSnackBarTampil(tester, kanal);

      await tester.tap(find.text('Urungkan'));
      // Snapshot berikutnya: ruas 3 sudah TIDAK tercapai lagi, jadi bloc
      // mengosongkan slot perayaan.
      kanal.add(buildState(snapshot: buildSnapshot(streak: 2)));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(find.byType(MilestoneToast), findsNothing);
    });

    testWidgets(
      'T-SEKALI: perayaan tampil TEPAT sekali — StreakMilestoneShown dikirim '
      'dan emisi berikutnya tidak memunculkan toast kedua',
      (tester) async {
        final bloc = MockStreakBloc();
        final kanal = StreamController<StreakState>.broadcast();
        addTearDown(kanal.close);

        await tester.pumpWidget(
          harnessTransisi(bloc, kanal.stream, sedangMenandai()),
        );
        await tandaiSampaiSnackBarTampil(tester, kanal);

        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        expect(find.byType(MilestoneToast), findsOneWidget);

        // Toast berdurasi 3 detik — biarkan habis supaya layar bersih
        // sebelum emisi berikutnya diuji.
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(find.byType(MilestoneToast), findsNothing);

        // `pendingCelebration` adalah antrean SATU SLOT. Tanpa
        // `StreakMilestoneShown`, slotnya tak pernah dikosongkan dan
        // perayaan yang sama bisa tampil lagi. Dua emisi berikut meniru
        // bloc yang sudah mengonsumsi slot lalu memancarkan snapshot segar.
        kanal.add(
          buildState(
            snapshot: buildSnapshot(todayStatus: DayStatus.safe, streak: 3),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();
        kanal.add(
          buildState(
            snapshot: buildSnapshot(todayStatus: DayStatus.safe, streak: 4),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(MilestoneToast), findsNothing);
        verify(
          () => bloc.add(any(that: isA<StreakMilestoneShown>())),
        ).called(1);
      },
    );
  });
}
