import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bills_bento_tile.dart';

/// Task 7.1 — tile Tagihan di dashboard: navigasi ke `/bills` + ringkasan
/// tagihan aktif terdekat (nama · relatif jatuh tempo) & jumlah "akan
/// datang". NOL data palsu: state non-success/kosong → copy jujur, badge
/// kosong (tidak dirender).
///
/// Menguji `BillsBentoTile` (widget publik hasil ekstraksi dari
/// `_BentoGrid`/`dashboard_page.dart`) secara terisolasi — bukan
/// `DashboardPage` penuh — supaya tidak perlu menyediakan seluruh bloc
/// dashboard (DashboardBloc/SurvivalBloc/BudgetLimitsBloc/dst) yang tak
/// relevan dengan tile ini.
class MockBillsBloc extends MockBloc<BillsEvent, BillsState>
    implements BillsBloc {}

// Delegate sinkron — rootBundle async bentrok dengan fakeAsync widget test
// (pola sama seperti bills_list_page_test.dart).
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
  late MockBillsBloc bloc;

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  BillEntity buildBill({
    required int id,
    required String name,
    required DateTime dueDate,
    BillStatus status = BillStatus.active,
  }) => BillEntity(
    id: id,
    name: name,
    estimatedAmount: 500000,
    category: 'fixed',
    isFixedNeed: true,
    dueDate: dueDate,
    recurrence: Recurrence.monthly,
    installmentsPaid: 0,
    reminderEnabled: true,
    status: status,
    createdAt: todayStart,
    updatedAt: todayStart,
  );

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    bloc = MockBillsBloc();
  });

  void stub(BillsState state) {
    whenListen(bloc, Stream<BillsState>.value(state), initialState: state);
  }

  // Router dua-rute minimal: '/' merender tile dalam Scaffold, '/bills'
  // merender penanda supaya navigasi dapat diverifikasi tanpa menyeret
  // BillsListPage sungguhan (yang butuh bloc penuh berbeda kebutuhan).
  GoRouter buildTestRouter() => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: BlocProvider<BillsBloc>.value(
            value: bloc,
            child: const BillsBentoTile(),
          ),
        ),
      ),
      GoRoute(
        path: '/bills',
        builder: (context, state) =>
            const Scaffold(body: Text('BILLS_PAGE_MARKER')),
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

  testWidgets('tap tile → navigasi ke /bills (BUKAN snackbar Segera hadir)', (
    tester,
  ) async {
    stub(const BillsState(status: BillsStatus.success));
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text('BILLS_PAGE_MARKER'), findsNothing);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    // Titik anti-sabotase: kalau onTap kembali memanggil snackbar
    // "Segera hadir" alih-alih context.push('/bills'), marker TIDAK akan
    // muncul dan assertion ini GAGAL.
    expect(find.text('BILLS_PAGE_MARKER'), findsOneWidget);
    expect(find.text(l10n.commonComingSoon), findsNothing);
  });

  testWidgets('2 tagihan aktif → sub tampilkan nama+relatif tagihan TERDEKAT, '
      'badge tampilkan jumlah', (tester) async {
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [
          buildBill(
            id: 1,
            name: 'Wifi Indihome',
            dueDate: todayStart.add(const Duration(days: 5)),
          ),
          buildBill(
            id: 2,
            name: 'Kos Bu Tini',
            dueDate: todayStart.add(const Duration(days: 2)),
          ),
        ],
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    // "Kos Bu Tini" jatuh tempo lebih dekat (+2 hari) daripada
    // "Wifi Indihome" (+5 hari) → itu yang tampil di sub.
    expect(find.textContaining('Kos Bu Tini'), findsOneWidget);
    expect(find.textContaining(l10n.daysLeft(2)), findsOneWidget);
    expect(find.textContaining('Wifi Indihome'), findsNothing);
    expect(find.text(l10n.billsUpcomingCount(2)), findsOneWidget);
  });

  testWidgets(
    'tanpa tagihan → sub copy kosong yang jujur, badge tak dirender',
    (tester) async {
      stub(const BillsState(status: BillsStatus.success));
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.text(l10n.dashboardBentoBillsSub), findsOneWidget);
      // Tak boleh ada sisa data palsu era coming-soon.
      expect(find.text('2 JT'), findsNothing);
      expect(find.textContaining('akan datang'), findsNothing);
    },
  );

  testWidgets(
    'state initial/loading/failure → tetap perlakukan seperti tanpa data '
    '(tak ada angka palsu)',
    (tester) async {
      stub(const BillsState());
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.text(l10n.dashboardBentoBillsSub), findsOneWidget);
      expect(find.textContaining('akan datang'), findsNothing);
    },
  );

  testWidgets('tagihan terlambat → sub berbunyi "Terlambat"', (tester) async {
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [
          buildBill(
            id: 1,
            name: 'Kos Bu Tini',
            dueDate: todayStart.subtract(const Duration(days: 3)),
          ),
        ],
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.textContaining(l10n.billsStatusOverdue), findsOneWidget);
  });

  testWidgets('tagihan jatuh tempo hari ini → sub berbunyi "Jatuh tempo hari '
      'ini" (bukan Terlambat)', (tester) async {
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [buildBill(id: 1, name: 'Kos Bu Tini', dueDate: todayStart)],
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.textContaining(l10n.billsDueToday), findsOneWidget);
    expect(find.textContaining(l10n.billsStatusOverdue), findsNothing);
  });

  testWidgets('dark mode render tanpa error', (tester) async {
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [
          buildBill(
            id: 1,
            name: 'Kos Bu Tini',
            dueDate: todayStart.add(const Duration(days: 1)),
          ),
        ],
      ),
    );
    await tester.pumpWidget(harness(theme: ThemeData.dark()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
