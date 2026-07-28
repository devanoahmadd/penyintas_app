import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/mark_bill_paid_sheet.dart';
import 'package:penyintas_app/widgets/common/milestone_toast.dart';

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
  late StreamController<BillsState> stateController;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
    // BillsEvent sealed — pakai event konkret sebagai fallback.
    registerFallbackValue(const BillsSubscribed());
  });

  setUp(() {
    bloc = MockBillsBloc();
    // Broadcast: `close()` pada controller single-subscription yang tak pernah
    // di-listen tidak pernah selesai → tear-down menggantung.
    stateController = StreamController<BillsState>.broadcast();
    whenListen(
      bloc,
      stateController.stream,
      initialState: const BillsState(status: BillsStatus.success),
    );
  });

  tearDown(() {
    stateController.close();
  });

  final createdAt = DateTime(2026, 1, 5);

  /// Tagihan bulanan berjalan (cicilan 3 dari 12) — setelah dibayar sekali
  /// masih `active`, jadi milestone WAJIB muncul.
  BillEntity billBerjalan({
    int estimatedAmount = 750000,
    bool isFixedNeed = false,
    String category = 'internet',
  }) => BillEntity(
    id: 7,
    cloudId: 'cloud-7',
    name: 'Wifi Indihome',
    estimatedAmount: estimatedAmount,
    category: category,
    isFixedNeed: isFixedNeed,
    dueDate: DateTime(2026, 8, 10),
    recurrence: Recurrence.monthly,
    installmentTotal: 12,
    installmentsPaid: 3,
    dueDayOfMonth: 10,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  /// Tagihan sekali-jalan — setelah dibayar langsung `completed`, jadi
  /// milestone TIDAK boleh muncul.
  BillEntity billSekaliJalan() => BillEntity(
    id: 9,
    name: 'Servis Motor',
    estimatedAmount: 200000,
    category: 'transport',
    isFixedNeed: false,
    dueDate: DateTime(2026, 8, 10),
    recurrence: Recurrence.none,
    installmentsPaid: 0,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  Widget harness({required BillEntity bill, ThemeData? theme}) => MaterialApp(
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme,
    home: Scaffold(
      body: Builder(
        builder: (ctx) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: BlocProvider<BillsBloc>.value(
                    value: bloc,
                    child: MarkBillPaidSheet(bill: bill),
                  ),
                ),
              ),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    ),
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required BillEntity bill,
    ThemeData? theme,
  }) async {
    // Layar tinggi supaya sheet muat tanpa banyak scroll.
    tester.view.physicalSize = const Size(600, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(bill: bill, theme: theme));
    // Delegate l10n resolve di frame berikutnya — tanpa pump ekstra body
    // MaterialApp belum terbangun sama sekali.
    await tester.pumpAndSettle();
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  /// Tekan tombol konfirmasi. SENGAJA tanpa `pumpAndSettle`: saat submit valid,
  /// tombol berganti jadi CircularProgressIndicator yang berputar selamanya.
  Future<void> tapSubmit(WidgetTester tester) async {
    final finder = find.byKey(const ValueKey('bill_paid_submit'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  BillsEvent captureLastEvent(WidgetTester tester) {
    final captured = verify(() => bloc.add(captureAny())).captured;
    return captured.last as BillsEvent;
  }

  BillMarkedPaid captureMarkedPaid(WidgetTester tester) {
    final event = captureLastEvent(tester);
    expect(event, isA<BillMarkedPaid>());
    return event as BillMarkedPaid;
  }

  String fieldText(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

  bool switchValue(WidgetTester tester, String key) =>
      tester.widget<Switch>(find.byKey(ValueKey(key))).value;

  DateTime hariIni() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ── (a) Nominal default = estimasi, dan EDITABLE ──────────────────────────

  testWidgets('nominal default = estimatedAmount tagihan', (tester) async {
    await pumpSheet(tester, bill: billBerjalan(estimatedAmount: 750000));

    expect(
      fieldText(tester, 'bill_paid_amount'),
      '750000',
      reason: 'nominal aktual diprefill dari perkiraan tagihan',
    );
  });

  testWidgets(
    'nominal editable → payload memakai nilai yang diketik pengguna',
    (tester) async {
      await pumpSheet(tester, bill: billBerjalan(estimatedAmount: 750000));

      await tester.enterText(
        find.byKey(const ValueKey('bill_paid_amount')),
        '812500',
      );
      await tester.pump();

      await tapSubmit(tester);

      final event = captureMarkedPaid(tester);
      expect(
        event.actualAmount,
        812500,
        reason:
            'pengguna bisa bayar beda dari perkiraan — nominal harus editable',
      );
    },
  );

  // ── (b) Opt-out — TITIK ANTI-SABOTASE ─────────────────────────────────────

  testWidgets('toggle opt-out ON → BillMarkedPaid.optOutTransaction == true', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());

    expect(
      switchValue(tester, 'bill_paid_optout'),
      isFalse,
      reason: 'default: transaksi tetap dibuat',
    );

    await tapKey(tester, 'bill_paid_optout');
    expect(switchValue(tester, 'bill_paid_optout'), isTrue);

    await tapSubmit(tester);

    final event = captureMarkedPaid(tester);
    expect(
      event.optOutTransaction,
      isTrue,
      reason:
          'opt-out ON WAJIB diteruskan ke BLoC — kalau tidak, transaksi ganda '
          'tercatat padahal pengguna sudah mencatat manual',
    );
  });

  testWidgets('opt-out OFF (default) → optOutTransaction == false', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    expect(captureMarkedPaid(tester).optOutTransaction, isFalse);
  });

  // ── (c) Payload lengkap ───────────────────────────────────────────────────

  testWidgets('konfirmasi emit BillMarkedPaid dengan payload yang benar', (
    tester,
  ) async {
    final bill = billBerjalan(estimatedAmount: 750000, isFixedNeed: true);
    await pumpSheet(tester, bill: bill);

    await tapSubmit(tester);

    final event = captureMarkedPaid(tester);
    expect(event.billId, bill.id);
    expect(event.actualAmount, 750000);
    expect(
      event.paidDate,
      hariIni(),
      reason: 'tanggal bayar default = hari ini (awal hari)',
    );
    expect(
      event.includeAsFixed,
      isTrue,
      reason: 'toggle kebutuhan tetap diprefill dari bill.isFixedNeed',
    );
    expect(event.optOutTransaction, isFalse);
  });

  // ── Toggle kebutuhan tetap ────────────────────────────────────────────────

  testWidgets('toggle kebutuhan tetap diprefill dari bill.isFixedNeed', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan(isFixedNeed: true));
    expect(switchValue(tester, 'bill_paid_fixed'), isTrue);
  });

  testWidgets('toggle kebutuhan tetap bisa diubah → payload ikut berubah', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan(isFixedNeed: false));

    expect(switchValue(tester, 'bill_paid_fixed'), isFalse);
    await tapKey(tester, 'bill_paid_fixed');
    expect(switchValue(tester, 'bill_paid_fixed'), isTrue);

    await tapSubmit(tester);

    expect(captureMarkedPaid(tester).includeAsFixed, isTrue);
  });

  // ── Kategori read-only ────────────────────────────────────────────────────

  testWidgets('kategori tampil read-only — tidak ada pilihan kategori lain', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan(category: 'internet'));

    expect(find.text(l10n.categoryInternet), findsOneWidget);
    // Kategori bukan field editable di sheet ini.
    expect(find.text(l10n.categoryFood), findsNothing);
    expect(find.text(l10n.categoryTransport), findsNothing);
    expect(find.text(l10n.categoryShopping), findsNothing);
  });

  // ── Validasi ──────────────────────────────────────────────────────────────

  testWidgets('nominal kosong → tervalidasi, BillMarkedPaid TIDAK ter-emit', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());

    await tester.enterText(find.byKey(const ValueKey('bill_paid_amount')), '');
    await tester.pump();

    await tapSubmit(tester);

    verifyNever(() => bloc.add(any(that: isA<BillMarkedPaid>())));
    expect(
      find.text(l10n.billsPaidErrorAmount),
      findsOneWidget,
      reason: 'pesan validasi nominal harus terlihat pengguna',
    );
  });

  // ── Umpan balik submit ────────────────────────────────────────────────────

  testWidgets('gagal → SnackBar tampil & tombol konfirmasi aktif lagi', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.failure));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.billsPaidFailed), findsOneWidget);
    expect(find.byType(MarkBillPaidSheet), findsOneWidget);
    // Tombol WAJIB aktif lagi — kalau `_isSubmitting` tak di-reset, pengguna
    // terkunci di sheet tanpa bisa mencoba ulang.
    final submit = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('bill_paid_submit')),
    );
    expect(
      submit.onPressed,
      isNotNull,
      reason: 'setelah gagal, konfirmasi harus bisa ditekan ulang',
    );
  });

  testWidgets('sukses → sheet ditutup', (tester) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    // Loncat melewati transisi pop sekali frame — `pumpAndSettle` akan
    // menggantung selama indikator loading masih ikut ter-render.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MarkBillPaidSheet), findsNothing);
    expect(find.text('buka'), findsOneWidget);
  });

  // ── Milestone dipindah ke halaman daftar (Task 5.4) ───────────────────────
  //
  // Sampai Task 5.3 sheet ini menampilkan `MilestoneToast` sendiri. Task 5.4
  // menyatukan perayaan + tawaran "Urungkan" jadi SATU snackbar milik
  // `BillsListPage`, karena `MilestoneToast.show` memanggil
  // `hideCurrentSnackBar()` — dua surface saling menggusur dan yang hilang
  // justru undo, jaring pengaman pengguna.
  //
  // Dua test lama ("MilestoneToast tampil" / "TANPA MilestoneToast") diganti
  // penjaga di bawah: sheet WAJIB diam. Pasangannya (isi & aksi snackbar) ada
  // di `bills_list_page_test.dart` grup "snackbar undo".

  testWidgets('sukses → sheet TIDAK menampilkan surface apa pun sendiri', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byType(MilestoneToast),
      findsNothing,
      reason: 'perayaan kini digabung ke snackbar undo di BillsListPage',
    );
    expect(find.text(l10n.milestoneCopy), findsNothing);
  });

  testWidgets('sukses & tagihan sekali jalan → sheet tetap diam', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billSekaliJalan());
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MilestoneToast), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  // ── Aksesibilitas & tema ──────────────────────────────────────────────────

  testWidgets('tombol konfirmasi & baris toggle memenuhi hit target 48dp', (
    tester,
  ) async {
    await pumpSheet(tester, bill: billBerjalan());

    final submitSize = tester.getSize(
      find.byKey(const ValueKey('bill_paid_submit')),
    );
    expect(submitSize.height, greaterThanOrEqualTo(48.0));

    final optOutRow = tester.getSize(
      find.byKey(const ValueKey('bill_paid_optout_row')),
    );
    expect(optOutRow.height, greaterThanOrEqualTo(48.0));

    final dateSize = tester.getSize(
      find.byKey(const ValueKey('bill_paid_date')),
    );
    expect(dateSize.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('dark mode render tanpa error', (tester) async {
    await pumpSheet(tester, bill: billBerjalan(), theme: ThemeData.dark());

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.billsPaidTitle), findsOneWidget);
  });
}
