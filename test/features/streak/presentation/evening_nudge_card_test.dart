import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';
import 'package:penyintas_app/features/streak/presentation/widgets/evening_nudge_card.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';

/// Task 17, spec §9.2 — kartu sore di dashboard: bertanya, bukan menagih.
///
/// Muncul HANYA bila hari ini belum aman DAN waktu lokal >= ambang
/// `min(17:00, jam pengingat harian user)`. Pengingat mati -> ambang tetap
/// 17:00. Sumber waktu WAJIB disuntik lewat `AppClock` — ambang diuji pada
/// 16:59/17:00/16:00 dan mustahil deterministik lewat `DateTime.now()`.
class MockStreakBloc extends MockBloc<StreakEvent, StreakState>
    implements StreakBloc {}

class MockSurvivalBloc extends MockBloc<SurvivalEvent, SurvivalState>
    implements SurvivalBloc {}

// Delegate sinkron — meniru pola `consistency_page_test.dart`, menghindari
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
    // `StreakEvent` sealed DAN tanpa Equatable: fallback-nya instance
    // sungguhan, verifikasinya memakai matcher TIPE — pola sama seperti
    // `consistency_page_test.dart`.
    registerFallbackValue(StreakRefreshed());
  });

  StreakSnapshot buildSnapshot({
    bool hasStarted = true,
    DayStatus todayStatus = DayStatus.pending,
  }) => StreakSnapshot(
    hasStarted: hasStarted,
    activatedDay: 20260101,
    currentStreak: 12,
    longestRuas: 21,
    graceAvailable: 2,
    graceUsedDays: const {},
    todayStatus: todayStatus,
    today: 20260905,
    nextLastSeenDay: 20260905,
    lastBreakDay: null,
    brokenRunLength: 0,
    markedDays: const {},
    markedDaysAll: const {},
    transactionDays: const {},
    clockAnomalyDetected: false,
  );

  StreakState buildState({
    StreakStatus status = StreakStatus.ready,
    StreakSnapshot? snapshot,
    bool isMarking = false,
  }) => StreakState(status: status, snapshot: snapshot, isMarking: isMarking);

  final survivalEntity = const SurvivalModeEntity(
    isActive: true,
    remainingAmount: 50000,
    remainingDays: 3,
    suggestedDailyBudget: 16000,
    tips: [],
  );

  Widget harness({
    required StreakState streakState,
    SurvivalState survivalState = const SurvivalInactive(),
    required DateTime now,
    int reminderHour = 20,
    int reminderMinute = 0,
    bool reminderEnabled = true,
    VoidCallback? onRecord,
  }) {
    final streakBloc = MockStreakBloc();
    whenListen(
      streakBloc,
      Stream<StreakState>.value(streakState),
      initialState: streakState,
    );
    final survivalBloc = MockSurvivalBloc();
    whenListen(
      survivalBloc,
      Stream<SurvivalState>.value(survivalState),
      initialState: survivalState,
    );

    return MaterialApp(
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: [
        _SyncL10nDelegate(l10n),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<StreakBloc>.value(value: streakBloc),
            BlocProvider<SurvivalBloc>.value(value: survivalBloc),
          ],
          child: EveningNudgeCard(
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            reminderEnabled: reminderEnabled,
            clock: FixedClock(now),
            onRecord: onRecord ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('tidak muncul sebelum ambang (16:59, pengingat 20:00)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        now: DateTime(2026, 9, 5, 16, 59),
        reminderHour: 20,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('evening-nudge-card')), findsNothing);
  });

  testWidgets('muncul pada 17:00 saat pengingat 20:00 (ambang = min(17,20))', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        now: DateTime(2026, 9, 5, 17, 0),
        reminderHour: 20,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('evening-nudge-card')), findsOneWidget);
  });

  testWidgets('muncul pada 16:00 saat pengingat 16:00 (ambang = min(17,16))', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        now: DateTime(2026, 9, 5, 16, 0),
        reminderHour: 16,
        reminderMinute: 0,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('evening-nudge-card')), findsOneWidget);
  });

  testWidgets('ambang tetap 17:00 saat pengingat dimatikan', (tester) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        now: DateTime(2026, 9, 5, 16, 0),
        reminderHour: 16,
        reminderMinute: 0,
        reminderEnabled: false,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('evening-nudge-card')), findsNothing);
  });

  testWidgets('tidak muncul saat hari ini sudah aman', (tester) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(
          snapshot: buildSnapshot(todayStatus: DayStatus.safe),
        ),
        now: DateTime(2026, 9, 5, 20, 0),
        reminderHour: 20,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('evening-nudge-card')), findsNothing);
  });

  testWidgets('tidak muncul saat hasStarted == false', (tester) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(
          snapshot: buildSnapshot(hasStarted: false),
        ),
        now: DateTime(2026, 9, 5, 20, 0),
        reminderHour: 20,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('evening-nudge-card')), findsNothing);
  });

  testWidgets('Survival Mode aktif melunakkan nadanya', (tester) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        survivalState: SurvivalActive(survivalEntity),
        now: DateTime(2026, 9, 5, 20, 0),
        reminderHour: 20,
      ),
    );
    await tester.pump();

    expect(
      find.text('Kalau sempat, catat ya. Nggak apa-apa kalau belum.'),
      findsOneWidget,
    );
    expect(
      find.text('Belum ada catatan hari ini. Memang belum ada pengeluaran?'),
      findsNothing,
    );
  });

  testWidgets('judul biasa (non-Survival) tampil apa adanya', (tester) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        now: DateTime(2026, 9, 5, 20, 0),
        reminderHour: 20,
      ),
    );
    await tester.pump();

    expect(
      find.text('Belum ada catatan hari ini. Memang belum ada pengeluaran?'),
      findsOneWidget,
    );
  });

  testWidgets('memakai token card, bukan warn', (tester) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        now: DateTime(2026, 9, 5, 20, 0),
        reminderHour: 20,
      ),
    );
    await tester.pump();

    final container = tester.widget<Container>(
      find.byKey(const Key('evening-nudge-card')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.cardLight);
    expect(decoration.color, isNot(AppColors.warn));
  });

  testWidgets('kedua tombol >= 48dp (hit target Android)', (tester) async {
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        now: DateTime(2026, 9, 5, 20, 0),
        reminderHour: 20,
      ),
    );
    await tester.pump();

    final noSpendSize = tester.getSize(
      find.byKey(const Key('evening-nudge-no-spend')),
    );
    final recordSize = tester.getSize(
      find.byKey(const Key('evening-nudge-record')),
    );
    expect(noSpendSize.height, greaterThanOrEqualTo(48));
    expect(recordSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets('tombol Tidak ada pengeluaran mengirim StreakTodayMarked', (
    tester,
  ) async {
    final streakBloc = MockStreakBloc();
    final state = buildState(snapshot: buildSnapshot());
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

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: [
          _SyncL10nDelegate(l10n),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<StreakBloc>.value(value: streakBloc),
              BlocProvider<SurvivalBloc>.value(value: survivalBloc),
            ],
            child: EveningNudgeCard(
              reminderHour: 20,
              reminderMinute: 0,
              reminderEnabled: true,
              clock: FixedClock(DateTime(2026, 9, 5, 20, 0)),
              onRecord: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('evening-nudge-no-spend')));
    await tester.pump();

    verify(() => streakBloc.add(any(that: isA<StreakTodayMarked>()))).called(
      1,
    );
  });

  testWidgets('tombol Catat memanggil onRecord, BUKAN buka sheet kedua', (
    tester,
  ) async {
    var recordTapped = 0;
    await tester.pumpWidget(
      harness(
        streakState: buildState(snapshot: buildSnapshot()),
        now: DateTime(2026, 9, 5, 20, 0),
        reminderHour: 20,
        onRecord: () => recordTapped++,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('evening-nudge-record')));
    await tester.pump();

    expect(recordTapped, 1);
  });
}
