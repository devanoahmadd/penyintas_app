import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/bills/presentation/pages/bills_list_page.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_item.dart';

class MockBillsBloc extends MockBloc<BillsEvent, BillsState>
    implements BillsBloc {}

// Delegate sinkron — rootBundle async bentrok dengan fakeAsync widget test.
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
    int estimatedAmount = 750000,
    BillStatus status = BillStatus.active,
    int? installmentTotal,
    int installmentsPaid = 0,
  }) => BillEntity(
    id: id,
    name: name,
    estimatedAmount: estimatedAmount,
    category: 'fixed',
    isFixedNeed: true,
    dueDate: dueDate,
    recurrence: Recurrence.monthly,
    installmentTotal: installmentTotal,
    installmentsPaid: installmentsPaid,
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

  Widget harness({ThemeData? theme}) => MaterialApp(
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme,
    home: BlocProvider<BillsBloc>.value(
      value: bloc,
      child: const BillsListPage(),
    ),
  );

  testWidgets('mengirim BillsSubscribed saat halaman pertama tampil', (
    tester,
  ) async {
    stub(const BillsState());
    await tester.pumpWidget(harness());
    await tester.pump();

    verify(() => bloc.add(const BillsSubscribed())).called(1);
  });

  testWidgets('status loading → indikator loading tampil', (tester) async {
    stub(const BillsState(status: BillsStatus.loading));
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('daftar kosong → copy empty state tampil', (tester) async {
    stub(const BillsState(status: BillsStatus.success));
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text(l10n.billsEmpty), findsOneWidget);
  });

  testWidgets('status failure → pesan error + tombol coba lagi memicu retry', (
    tester,
  ) async {
    stub(
      const BillsState(
        status: BillsStatus.failure,
        failure: CacheFailure('boom'),
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text(l10n.billsError), findsOneWidget);
    expect(find.text(l10n.retry), findsOneWidget);

    await tester.tap(find.text(l10n.retry));
    await tester.pump();

    // 1× dari initState + 1× dari tombol retry.
    verify(() => bloc.add(const BillsSubscribed())).called(2);
  });

  testWidgets('tagihan terlambat naik ke ATAS, sisanya urut jatuh tempo', (
    tester,
  ) async {
    // Urutan masukan sengaja diacak: kalau widget mengembalikan apa adanya,
    // "Wifi Indihome" yang muncul paling atas. Kalau widget hanya mengurutkan
    // dueDate menaik, "Cicilan Laptop" (paling lampau) yang paling atas.
    // Hanya pengangkatan overdue yang menaruh "Kos Bu Tini" di posisi teratas.
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [
          buildBill(
            id: 1,
            name: 'Wifi Indihome',
            dueDate: todayStart.add(const Duration(days: 3)),
          ),
          buildBill(
            id: 2,
            name: 'Kos Bu Tini',
            dueDate: todayStart.subtract(const Duration(days: 1)),
          ),
          buildBill(
            id: 3,
            name: 'Cicilan Laptop',
            dueDate: todayStart.subtract(const Duration(days: 10)),
            status: BillStatus.completed,
          ),
        ],
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    final kosY = tester.getTopLeft(find.text('Kos Bu Tini')).dy;
    final laptopY = tester.getTopLeft(find.text('Cicilan Laptop')).dy;
    final wifiY = tester.getTopLeft(find.text('Wifi Indihome')).dy;

    expect(
      kosY,
      lessThan(laptopY),
      reason: 'tagihan terlambat harus di atas tagihan selesai',
    );
    expect(laptopY, lessThan(wifiY), reason: 'sisanya urut jatuh tempo menaik');
  });

  testWidgets('chip status berteks: Terlambat / Akan datang / Selesai', (
    tester,
  ) async {
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [
          buildBill(
            id: 1,
            name: 'Kos Bu Tini',
            dueDate: todayStart.subtract(const Duration(days: 1)),
          ),
          buildBill(
            id: 2,
            name: 'Wifi Indihome',
            dueDate: todayStart.add(const Duration(days: 3)),
          ),
          buildBill(
            id: 3,
            name: 'Cicilan Laptop',
            dueDate: todayStart.subtract(const Duration(days: 10)),
            status: BillStatus.completed,
          ),
        ],
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text(l10n.billsStatusOverdue.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.billsStatusUpcoming.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.billsStatusDone.toUpperCase()), findsOneWidget);
  });

  testWidgets('nominal diformat rupiah + badge cicilan tampil', (tester) async {
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [
          buildBill(
            id: 1,
            name: 'Cicilan Motor',
            dueDate: todayStart.add(const Duration(days: 2)),
            installmentTotal: 12,
            installmentsPaid: 3,
          ),
        ],
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text(formatRupiah(750000)), findsOneWidget);
    expect(
      find.text(l10n.billsInstallmentProgress(4, 12).toUpperCase()),
      findsOneWidget,
    );
  });

  testWidgets('area tap tiap baris minimal 48dp', (tester) async {
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [
          buildBill(
            id: 1,
            name: 'Kos Bu Tini',
            dueDate: todayStart.add(const Duration(days: 2)),
          ),
        ],
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    final size = tester.getSize(find.byType(BillItem));
    expect(size.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('dark mode render tanpa error', (tester) async {
    stub(
      BillsState(
        status: BillsStatus.success,
        bills: [
          buildBill(
            id: 1,
            name: 'Kos Bu Tini',
            dueDate: todayStart.subtract(const Duration(days: 1)),
          ),
        ],
      ),
    );
    await tester.pumpWidget(harness(theme: ThemeData.dark()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Kos Bu Tini'), findsOneWidget);
    expect(find.text(l10n.billsStatusOverdue.toUpperCase()), findsOneWidget);
  });

  // ── Snackbar hasil pembayaran + Undo (Task 5.4) ─────────────────────────────
  //
  // SATU snackbar saja untuk kedua maksud (perayaan + jaring pengaman undo):
  // `MilestoneToast.show` memanggil `hideCurrentSnackBar()`, jadi kalau sheet
  // ikut menampilkan toast, snackbar Undo-lah yang tergusur.
  group('snackbar undo', () {
    final snapshot = UndoSnapshot(
      billId: 7,
      dueDate: todayStart.subtract(const Duration(days: 30)),
      installmentsPaid: 3,
      status: BillStatus.active,
      txId: 'tx-abc',
    );

    /// State awal SENGAJA tanpa `lastUndo` — `listenWhen` hanya lolos kalau
    /// `lastUndo` benar-benar BERUBAH.
    void stubUndo(BillsState next) {
      whenListen(
        bloc,
        Stream<BillsState>.value(next),
        initialState: const BillsState(status: BillsStatus.success),
      );
    }

    BillsState stateWithUndo({required List<BillEntity> bills}) => BillsState(
      status: BillsStatus.success,
      bills: bills,
      lastUndo: snapshot,
    );

    testWidgets(
      'tagihan masih berjalan (masih ada di daftar aktif) → snackbar milestone',
      (tester) async {
        stubUndo(
          stateWithUndo(
            bills: [
              buildBill(
                id: 7,
                name: 'Wifi Indihome',
                dueDate: todayStart.add(const Duration(days: 3)),
              ),
            ],
          ),
        );
        await tester.pumpWidget(harness());
        await tester.pump();
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text(l10n.milestoneCopy), findsOneWidget);
        expect(find.text(l10n.billsUndo), findsOneWidget);
      },
    );

    testWidgets(
      'tagihan sudah tamat (lenyap dari daftar aktif) → snackbar lunas semua',
      (tester) async {
        // `watchActiveBills` hanya mengalirkan bill aktif, jadi hilangnya bill
        // dari `state.bills` = penanda tagihan sudah selesai sepenuhnya.
        stubUndo(stateWithUndo(bills: const []));
        await tester.pumpWidget(harness());
        await tester.pump();
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text(l10n.billsPaidDone), findsOneWidget);
        expect(find.text(l10n.milestoneCopy), findsNothing);
        expect(find.text(l10n.billsUndo), findsOneWidget);
      },
    );

    testWidgets('tap "Urungkan" mengirim BillPaymentUndone dengan snapshot '
        'yang persis sama', (tester) async {
      stubUndo(
        stateWithUndo(
          bills: [
            buildBill(
              id: 7,
              name: 'Wifi Indihome',
              dueDate: todayStart.add(const Duration(days: 3)),
            ),
          ],
        ),
      );
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.pump();
      // Selama animasi masuk, snackbar masih dibungkus IgnorePointer —
      // tap-nya meleset kalau tidak ditunggu sampai diam.
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.text(l10n.billsUndo));
      await tester.pump();

      verify(() => bloc.add(BillPaymentUndone(snapshot))).called(1);
    });
  });
}
