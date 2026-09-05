import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';
import 'package:penyintas_app/features/streak/presentation/pages/consistency_page.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';
import 'package:penyintas_app/widgets/common/count_up_text.dart';

class MockStreakBloc extends MockBloc<StreakEvent, StreakState>
    implements StreakBloc {}

class MockSurvivalBloc extends MockBloc<SurvivalEvent, SurvivalState>
    implements SurvivalBloc {}

// Delegate sinkron — meniru pola `bills_list_page_test.dart`, menghindari
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

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
    // `StreakEvent` sealed DAN tanpa Equatable: ia tak bisa di-`Fake` dari
    // library lain, dan dua instance `StreakTodayMarkUndone()` tidak pernah
    // sama. Jadi fallback-nya instance event sungguhan, dan verifikasinya
    // memakai matcher TIPE, bukan kesetaraan nilai.
    registerFallbackValue(StreakRefreshed());
  });

  /// Fixture snapshot — nilai default meniru pengguna yang sudah berjalan
  /// (streak 12 hari), hari ini masih `pending` (belum ditandai, belum ada
  /// transaksi). Override lewat parameter named sesuai kebutuhan tiap test.
  StreakSnapshot buildSnapshot({
    bool hasStarted = true,
    int streak = 12,
    int longestRuas = 21,
    int graceAvailable = 2,
    DayStatus todayStatus = DayStatus.pending,
    int today = 20260905,
    int activatedDay = 20260101,
    Set<int> markedDaysAll = const {},
    bool clockAnomalyDetected = false,
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
    lastBreakDay: null,
    brokenRunLength: 0,
    markedDays: const {},
    markedDaysAll: markedDaysAll,
    transactionDays: const {},
    clockAnomalyDetected: clockAnomalyDetected,
  );

  StreakState buildState({
    StreakStatus status = StreakStatus.ready,
    StreakSnapshot? snapshot,
    Failure? failure,
    bool isMarking = false,
  }) => StreakState(
    status: status,
    snapshot: snapshot,
    failure: failure,
    isMarking: isMarking,
  );

  final survivalEntity = const SurvivalModeEntity(
    isActive: true,
    remainingAmount: 50000,
    remainingDays: 3,
    suggestedDailyBudget: 16000,
    tips: [],
  );

  /// Pembungkus MaterialApp bersama untuk `harness()` dan `harnessTransisi()`.
  Widget bungkus({
    required StreakBloc streakBloc,
    required SurvivalBloc survivalBloc,
    bool disableAnimations = false,
  }) => MaterialApp(
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: MediaQuery(
      data: const MediaQueryData().copyWith(
        disableAnimations: disableAnimations,
      ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<StreakBloc>.value(value: streakBloc),
          BlocProvider<SurvivalBloc>.value(value: survivalBloc),
        ],
        child: const ConsistencyPage(),
      ),
    ),
  );

  Widget harness({
    required StreakState state,
    SurvivalState survivalState = const SurvivalInactive(),
    bool disableAnimations = false,
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
      Stream<SurvivalState>.value(survivalState),
      initialState: survivalState,
    );

    return bungkus(
      streakBloc: streakBloc,
      survivalBloc: survivalBloc,
      disableAnimations: disableAnimations,
    );
  }

  /// Varian harness untuk test `BlocListener`. `listenWhen` di halaman
  /// membandingkan state SEBELUM dan SESUDAH, jadi ia menuntut TRANSISI —
  /// satu state tunggal seperti di `harness()` tidak akan pernah memicunya,
  /// dan itulah sebabnya seluruh jalur SnackBar lolos dari Step 2. Bloc-nya
  /// diserahkan pemanggil supaya test bisa memverifikasi event yang di-add
  /// BALIK oleh tombol di dalam SnackBar.
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

  testWidgets('status ready menampilkan angka streak dan label', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(state: buildState(snapshot: buildSnapshot(streak: 12))),
    );
    await tester.pump();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('hari berturut'), findsOneWidget);
  });

  testWidgets('status restoring menampilkan skeleton, BUKAN angka 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(state: buildState(status: StreakStatus.restoring)),
    );
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.byKey(const Key('consistency-skeleton')), findsOneWidget);
  });

  testWidgets('status failure menampilkan pesan + tombol coba lagi, '
      'BUKAN angka 0 dan BUKAN kalender kosong', (tester) async {
    await tester.pumpWidget(
      harness(
        state: buildState(
          status: StreakStatus.failure,
          failure: const CacheFailure(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.byKey(const Key('consistency-calendar')), findsNothing);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('hasStarted == false menampilkan empty state, bukan angka 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        state: buildState(
          snapshot: buildSnapshot(
            hasStarted: false,
            streak: 0,
            longestRuas: 0,
            graceAvailable: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Belum ada catatan. Mulai dari satu pengeluaran kecil hari ini.',
      ),
      findsOneWidget,
    );
    expect(find.text('0'), findsNothing);
  });

  testWidgets('CTA HILANG (bukan disabled) saat hari ini sudah aman', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        state: buildState(snapshot: buildSnapshot(todayStatus: DayStatus.safe)),
      ),
    );
    await tester.pump();

    expect(find.text('Hari ini tidak ada pengeluaran'), findsNothing);
    expect(find.text('Hari ini sudah tercatat'), findsOneWidget);
  });

  testWidgets('CTA nonaktif selagi isMarking — guard tap-ganda', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        state: buildState(
          snapshot: buildSnapshot(todayStatus: DayStatus.pending),
          isMarking: true,
        ),
      ),
    );
    await tester.pump();

    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('Survival Mode aktif membingkai angka sebagai bertahan', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        state: buildState(snapshot: buildSnapshot(streak: 12)),
        survivalState: SurvivalActive(survivalEntity),
      ),
    );
    await tester.pump();

    expect(find.text('Hari ke-12 kamu bertahan'), findsOneWidget);
  });

  testWidgets('CTA memenuhi ambang sentuh 48dp', (tester) async {
    await tester.pumpWidget(
      harness(
        state: buildState(
          snapshot: buildSnapshot(todayStatus: DayStatus.pending),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('consistency-cta'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  // ── Koreksi B (Ruling T12-a review) — empat test tambahan ──

  testWidgets(
    'T-D11: CTA hilang & chip "sudah ditandai" saat markedDaysAll berisi '
    'hari ini walau todayStatus masih pending',
    (tester) async {
      await tester.pumpWidget(
        harness(
          state: buildState(
            snapshot: buildSnapshot(
              todayStatus: DayStatus.pending,
              today: 20260905,
              markedDaysAll: {20260905},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Hari ini tidak ada pengeluaran'), findsNothing);
      expect(find.text('Hari ini sudah ditandai.'), findsOneWidget);
    },
  );

  testWidgets('T-ANOM: CTA hilang & chip anomali saat todayStatus == anomaly', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        state: buildState(
          snapshot: buildSnapshot(todayStatus: DayStatus.anomaly),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Hari ini tidak ada pengeluaran'), findsNothing);
    expect(
      find.text('Jam perangkatmu sedang tidak pas. Hitungan kami tahan dulu.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'T-RAW: jalur failure tidak pernah merender pesan mentah dari Failure',
    (tester) async {
      await tester.pumpWidget(
        harness(
          state: buildState(
            status: StreakStatus.failure,
            failure: const CacheFailure('GALAT MENTAH JANGAN TAMPIL'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GALAT MENTAH JANGAN TAMPIL'), findsNothing);
      expect(find.text('Belum bisa memuat catatanmu.'), findsOneWidget);
    },
  );

  testWidgets(
    'T-ANIM: disableAnimations true merender Text biasa, bukan CountUpText',
    (tester) async {
      await tester.pumpWidget(
        harness(
          state: buildState(snapshot: buildSnapshot(streak: 7)),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(find.byType(CountUpText), findsNothing);
      expect(find.text('7'), findsOneWidget);
    },
  );

  group('Jalur SnackBar & sheet aturan — pintu yang tak disediakan Step 2', () {
    /// Semua test di grup ini memakai transisi `isMarking: true -> false`,
    /// karena itulah yang dibandingkan `listenWhen` di halaman.
    StreakState sedangMenandai() =>
        buildState(snapshot: buildSnapshot(), isMarking: true);

    testWidgets(
      'penandaan sukses memunculkan SnackBar beserta tombol Urungkan',
      (tester) async {
        final bloc = MockStreakBloc();
        final kanal = StreamController<StreakState>.broadcast();
        addTearDown(kanal.close);

        await tester.pumpWidget(
          harnessTransisi(bloc, kanal.stream, sedangMenandai()),
        );
        // WAJIB sebelum `kanal.add`: delegate l10n `load()` bersifat async, jadi
        // `Localizations` menahan subtree-nya selama satu frame — halaman belum
        // ter-mount dan `BlocListener` belum berlangganan. Menembak ke
        // `StreamController.broadcast()` yang belum punya pelanggan membuang
        // event itu TANPA SUARA, dan testnya merah karena alasan yang salah.
        await tester.pump();
        kanal.add(
          buildState(snapshot: buildSnapshot(todayStatus: DayStatus.safe)),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Hari ini ditandai tanpa pengeluaran.'),
          findsOneWidget,
        );
        expect(find.text('Urungkan'), findsOneWidget);
      },
    );

    testWidgets(
      'SnackBar sukses MENGHILANG sesudah durasinya lewat (persist: false)',
      (tester) async {
        final bloc = MockStreakBloc();
        final kanal = StreamController<StreakState>.broadcast();
        addTearDown(kanal.close);

        await tester.pumpWidget(
          harnessTransisi(bloc, kanal.stream, sedangMenandai()),
        );
        // Lihat catatan pump-sebelum-add di test pertama grup ini.
        await tester.pump();
        kanal.add(
          buildState(snapshot: buildSnapshot(todayStatus: DayStatus.safe)),
        );
        await tester.pump();
        // Animasi MASUK harus tuntas dulu: timer auto-dismiss baru dipasang
        // sesudah SnackBar benar-benar terlihat, jadi tanpa ini penundaan di
        // bawah menghitung dari titik yang salah.
        await tester.pumpAndSettle();
        expect(
          find.text('Hari ini ditandai tanpa pengeluaran.'),
          findsOneWidget,
        );

        // SDK: `persist = persist ?? action != null`. SnackBar BERTOMBOL
        // karenanya default MENETAP dan mengabaikan `duration` di atasnya —
        // diam-diam, tanpa galat. Repo ini sudah pernah mengirimnya dalam
        // keadaan rusak di tiga lokasi (diperbaiki 2026-08-31), jadi aturan
        // yang sudah pernah patah sekali ini tidak boleh hidup tanpa penjaga.
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();

        expect(
          find.text('Hari ini ditandai tanpa pengeluaran.'),
          findsNothing,
          reason: 'SnackBar bertombol wajib tetap menghormati `duration`',
        );
      },
    );

    testWidgets('tombol Urungkan mengirim StreakTodayMarkUndone ke bloc', (
      tester,
    ) async {
      final bloc = MockStreakBloc();
      final kanal = StreamController<StreakState>.broadcast();
      addTearDown(kanal.close);

      await tester.pumpWidget(
        harnessTransisi(bloc, kanal.stream, sedangMenandai()),
      );
      // WAJIB sebelum `kanal.add`: delegate l10n `load()` bersifat async, jadi
      // `Localizations` menahan subtree-nya selama satu frame — halaman belum
      // ter-mount dan `BlocListener` belum berlangganan. Menembak ke
      // `StreamController.broadcast()` yang belum punya pelanggan membuang
      // event itu TANPA SUARA, dan testnya merah karena alasan yang salah.
      await tester.pump();
      kanal.add(
        buildState(snapshot: buildSnapshot(todayStatus: DayStatus.safe)),
      );
      await tester.pump();
      // Tanpa menuntaskan animasi masuk, tombolnya masih di y=624 — di luar
      // viewport test 800x600 — dan `tap()` menolak dengan "would not hit
      // test on the specified widget".
      await tester.pumpAndSettle();

      await tester.tap(find.text('Urungkan'));
      await tester.pump();

      verify(() => bloc.add(any(that: isA<StreakTodayMarkUndone>()))).called(1);
    });

    testWidgets(
      'penandaan gagal memakai key l10n, BUKAN pesan mentah dari Failure',
      (tester) async {
        final bloc = MockStreakBloc();
        final kanal = StreamController<StreakState>.broadcast();
        addTearDown(kanal.close);

        await tester.pumpWidget(
          harnessTransisi(bloc, kanal.stream, sedangMenandai()),
        );
        // Lihat catatan pump-sebelum-add di test pertama grup ini.
        await tester.pump();
        kanal.add(
          buildState(
            snapshot: buildSnapshot(),
            failure: const CacheFailure('GALAT MENTAH JANGAN TAMPIL'),
          ),
        );
        await tester.pump();
        await tester.pump();

        // T-RAW mengunci aturan yang sama untuk BADAN halaman. Penandaan yang
        // gagal lewat pintu yang sama sekali berbeda — SnackBar — jadi satu
        // test saja meninggalkan separuh aturan tanpa penjaga.
        expect(find.text('GALAT MENTAH JANGAN TAMPIL'), findsNothing);
        expect(find.text('Belum bisa menandai hari ini.'), findsOneWidget);
      },
    );

    testWidgets('ikon (?) di AppBar membuka sheet "Cara hitungnya"', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(state: buildState(snapshot: buildSnapshot())),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('consistency-help')));
      await tester.pumpAndSettle();

      expect(find.text('Cara hitungnya'), findsOneWidget);
    });
  });
}
