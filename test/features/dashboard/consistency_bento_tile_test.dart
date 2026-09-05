import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/consistency_bento_tile.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';

/// Task 16 — tile Konsistensi di dashboard: angka streak nyata dari
/// `StreakBloc`, TIDAK PERNAH "0 hari" palsu untuk status non-`ready`,
/// `hasStarted == false`, atau `failure`. Tap → `context.push('/consistency')`
/// (bukan `go`) supaya dashboard tetap di tumpukan navigasi (tombol back
/// berfungsi).
///
/// Menguji `ConsistencyBentoTile` terisolasi — bukan `DashboardPage` penuh —
/// meniru pola `dashboard_bills_tile_test.dart`.
class MockStreakBloc extends MockBloc<StreakEvent, StreakState>
    implements StreakBloc {}

// Delegate sinkron — rootBundle async bentrok dengan pumpWidget tanpa
// pumpAndSettle (pola sama seperti dashboard_bills_tile_test.dart).
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
  late MockStreakBloc bloc;

  StreakSnapshot buildSnapshot({
    bool hasStarted = true,
    int streak = 12,
  }) => StreakSnapshot(
    hasStarted: hasStarted,
    activatedDay: 20260101,
    currentStreak: streak,
    longestRuas: 21,
    graceAvailable: 2,
    graceUsedDays: const {},
    todayStatus: DayStatus.pending,
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
    Failure? failure,
  }) => StreakState(status: status, snapshot: snapshot, failure: failure);

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    bloc = MockStreakBloc();
  });

  void stub(StreakState state) {
    whenListen(bloc, Stream<StreakState>.value(state), initialState: state);
  }

  // Router dua-rute minimal: '/' merender dashboard palsu (dengan marker,
  // supaya bisa dibedakan dari `push` vs `go`) + tile, '/consistency'
  // merender penanda.
  GoRouter buildTestRouter() => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('DASHBOARD_PAGE_MARKER'),
              BlocProvider<StreakBloc>.value(
                value: bloc,
                child: const ConsistencyBentoTile(),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/consistency',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (innerContext) => Text(
              'CONSISTENCY_PAGE_MARKER canPop='
              '${Navigator.of(innerContext).canPop()}',
            ),
          ),
        ),
      ),
    ],
  );

  Widget harness({ThemeData? theme}) => MaterialApp.router(
    routerConfig: buildTestRouter(),
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme,
  );

  testWidgets('menampilkan angka streak nyata saat ready', (tester) async {
    stub(buildState(snapshot: buildSnapshot(streak: 12)));
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text('12 hari berturut'), findsOneWidget);
  });

  testWidgets(
    'hasStarted == false → sub-teks ajakan, BUKAN "0 hari"',
    (tester) async {
      stub(buildState(snapshot: buildSnapshot(hasStarted: false, streak: 0)));
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.text('Mulai hari ini'), findsOneWidget);
      expect(find.textContaining('0'), findsNothing);
    },
  );

  testWidgets('status restoring → skeleton, BUKAN "0 hari"', (tester) async {
    stub(buildState(status: StreakStatus.restoring));
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.textContaining('0'), findsNothing);
    expect(
      find.byKey(const Key('consistency-bento-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets('status failure → sub-teks netral, BUKAN "0 hari"', (
    tester,
  ) async {
    stub(
      buildState(status: StreakStatus.failure, failure: const CacheFailure()),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.textContaining('0'), findsNothing);
    expect(find.text('Mulai hari ini'), findsOneWidget);
    expect(
      find.byKey(const Key('consistency-bento-skeleton')),
      findsNothing,
    );
  });

  testWidgets(
    'tap membuka /consistency lewat push (dashboard tetap di tumpukan, '
    'back berfungsi)',
    (tester) async {
      stub(buildState(snapshot: buildSnapshot()));
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.textContaining('CONSISTENCY_PAGE_MARKER'), findsNothing);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Setelah settle, Flutter membuang overlay rute `/` yang sudah
      // tertutup opaque dari tree — jadi marker dashboard TIDAK bisa lagi
      // dipakai sebagai bukti. Sinyal yang benar-benar membedakan `push`
      // dari `go` adalah `Navigator.canPop()`: `push` MENUMPUK halaman baru
      // di atas halaman lama (canPop == true, tombol back berfungsi),
      // sedangkan `go` MENGGANTI seluruh tumpukan dengan lokasi baru
      // (canPop == false, tak ada apa pun untuk di-back). Dibuktikan
      // empiris lewat probe terpisah sebelum ditulis di sini.
      expect(
        find.text('CONSISTENCY_PAGE_MARKER canPop=true'),
        findsOneWidget,
      );
    },
  );

  testWidgets('dark mode render tanpa error', (tester) async {
    stub(buildState(snapshot: buildSnapshot(streak: 5)));
    await tester.pumpWidget(harness(theme: ThemeData.dark()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
