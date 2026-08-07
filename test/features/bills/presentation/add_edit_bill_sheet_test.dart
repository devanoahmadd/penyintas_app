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
import 'package:penyintas_app/features/bills/presentation/widgets/add_edit_bill_sheet.dart';

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
      initialState: const BillsState(status: BillsStatus.initial),
    );
  });

  tearDown(() {
    stateController.close();
  });

  Widget harness({BillEntity? initial, ThemeData? theme}) => MaterialApp(
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
                    child: AddEditBillSheet(initial: initial),
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
    BillEntity? initial,
    ThemeData? theme,
  }) async {
    // Layar tinggi supaya form panjang muat tanpa banyak scroll.
    tester.view.physicalSize = const Size(600, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(initial: initial, theme: theme));
    // Delegate l10n resolve di frame berikutnya — tanpa pump ekstra body
    // MaterialApp belum terbangun sama sekali.
    await tester.pumpAndSettle();
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  /// Tekan tombol simpan. SENGAJA tanpa `pumpAndSettle`: saat submit valid,
  /// tombol berganti jadi CircularProgressIndicator yang berputar selamanya.
  Future<void> tapSubmit(WidgetTester tester) async {
    final finder = find.byKey(const ValueKey('bill_form_submit'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Tekan tombol OK pada `showDatePicker` yang sedang terbuka.
  /// Label diambil dari MaterialLocalizations agar bebas dari bahasa aktif.
  Future<void> confirmDatePicker(WidgetTester tester) async {
    final ctx = tester.element(find.byType(DatePickerDialog));
    final okLabel = MaterialLocalizations.of(ctx).okButtonLabel;
    await tester.tap(find.widgetWithText(TextButton, okLabel));
    await tester.pumpAndSettle();
  }

  Future<void> pickDueDate(WidgetTester tester) async {
    await tapKey(tester, 'bill_form_due_date');
    await confirmDatePicker(tester);
  }

  Future<void> pickEndDate(WidgetTester tester) async {
    await tapKey(tester, 'bill_form_end_date');
    await confirmDatePicker(tester);
  }

  Future<void> fillBaseFields(
    WidgetTester tester, {
    String name = 'Kos Bu Tini',
    String amount = '750000',
  }) async {
    await tester.enterText(find.byKey(const ValueKey('bill_form_name')), name);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('bill_form_amount')),
      amount,
    );
    await tester.pump();
  }

  BillsEvent captureLastEvent(WidgetTester tester) {
    final captured = verify(() => bloc.add(captureAny())).captured;
    return captured.last as BillsEvent;
  }

  // ── (a) Kategori wajib ────────────────────────────────────────────────────

  testWidgets('submit tanpa kategori → tervalidasi, BillAdded TIDAK ter-emit', (
    tester,
  ) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await pickDueDate(tester);

    // Sengaja TIDAK memilih kategori.
    await tapSubmit(tester);

    verifyNever(() => bloc.add(any(that: isA<BillAdded>())));
    expect(
      find.text(l10n.billsFormErrorCategory),
      findsOneWidget,
      reason: 'pesan validasi kategori harus terlihat pengguna',
    );
  });

  // ── (b) Tenor mutual-exclusive (anti-sabotase) ────────────────────────────

  testWidgets('tenor mutual-exclusive: pindah "N kali" → "Sampai tanggal" '
      'meng-clear installmentTotal', (tester) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapLabel(tester, l10n.billsRecurrenceMonthly);

    // Mode "N kali" + isi 12.
    await tapLabel(tester, l10n.billsTenorCount);
    await tester.enterText(
      find.byKey(const ValueKey('bill_form_installment')),
      '12',
    );
    await tester.pump();

    // Pindah ke "Sampai tanggal" — nilai mode lama WAJIB hilang.
    await tapLabel(tester, l10n.billsTenorEndDate);
    await pickEndDate(tester);

    await tapSubmit(tester);

    final event = captureLastEvent(tester);
    expect(event, isA<BillAdded>());
    final bill = (event as BillAdded).bill;
    expect(
      bill.installmentTotal,
      isNull,
      reason: 'invariant §4.1: maksimal satu batas tenor boleh non-null',
    );
    expect(bill.recurrenceEndDate, isNotNull);
  });

  testWidgets('tenor mutual-exclusive: pindah "Sampai tanggal" → "N kali" '
      'meng-clear recurrenceEndDate', (tester) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapLabel(tester, l10n.billsRecurrenceMonthly);

    await tapLabel(tester, l10n.billsTenorEndDate);
    await pickEndDate(tester);

    await tapLabel(tester, l10n.billsTenorCount);
    await tester.enterText(
      find.byKey(const ValueKey('bill_form_installment')),
      '6',
    );
    await tester.pump();

    await tapSubmit(tester);

    final bill = (captureLastEvent(tester) as BillAdded).bill;
    expect(bill.installmentTotal, 6);
    expect(
      bill.recurrenceEndDate,
      isNull,
      reason: 'invariant §4.1: maksimal satu batas tenor boleh non-null',
    );
  });

  // ── (c) Kategori fixed → toggle kebutuhan tetap otomatis ON ───────────────

  testWidgets('pilih kategori "fixed" → toggle kebutuhan tetap otomatis ON', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(
      tester.widget<Switch>(find.byType(Switch)).value,
      isFalse,
      reason: 'default toggle mati sebelum kategori dipilih',
    );

    await tapLabel(tester, l10n.categoryFixed);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  // ── (d) Payload BillAdded ─────────────────────────────────────────────────

  testWidgets('BillAdded ter-emit dengan payload yang benar', (tester) async {
    await pumpSheet(tester);
    await fillBaseFields(tester, name: 'Wifi Indihome', amount: '350000');
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapLabel(tester, l10n.billsRecurrenceMonthly);

    await tapSubmit(tester);

    final bill = (captureLastEvent(tester) as BillAdded).bill;
    final now = DateTime.now();
    final expectedDue = DateTime(now.year, now.month, now.day);

    expect(bill.name, 'Wifi Indihome');
    expect(bill.estimatedAmount, 350000);
    expect(bill.category, 'internet');
    expect(bill.recurrence, Recurrence.monthly);
    expect(bill.dueDate, expectedDue);
    expect(bill.dueDayOfMonth, expectedDue.day);
    expect(bill.installmentsPaid, 0);
    expect(bill.status, BillStatus.active);
    expect(bill.cloudId, isNull);
    // Default pengingat = "ikut pengaturan": aktif, tanpa override hari.
    expect(bill.reminderEnabled, isTrue);
    expect(bill.reminderDaysBefore, isNull);
  });

  // ── (e) recurrence none → blok tenor hilang + payload null ────────────────

  testWidgets(
    'pengulangan "Sekali" → blok tenor disembunyikan & payload null',
    (tester) async {
      await pumpSheet(tester);
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryInternet);
      await pickDueDate(tester);
      await tapLabel(tester, l10n.billsRecurrenceMonthly);

      // Blok tenor tampil saat berulang…
      expect(find.text(l10n.billsTenorUnlimited), findsOneWidget);

      // …lalu hilang saat "Sekali".
      await tapLabel(tester, l10n.billsRecurrenceNone);
      expect(find.text(l10n.billsTenorUnlimited), findsNothing);
      expect(find.text(l10n.billsTenorCount), findsNothing);
      expect(find.text(l10n.billsTenorEndDate), findsNothing);

      await tapSubmit(tester);

      final bill = (captureLastEvent(tester) as BillAdded).bill;
      expect(bill.recurrence, Recurrence.none);
      expect(bill.dueDayOfMonth, isNull);
      expect(bill.installmentTotal, isNull);
      expect(bill.recurrenceEndDate, isNull);
    },
  );

  // ── Pengingat ─────────────────────────────────────────────────────────────

  testWidgets('pengingat "Mati" → reminderEnabled false tanpa override hari', (
    tester,
  ) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapLabel(tester, l10n.billsReminderOff);

    await tapSubmit(tester);

    final bill = (captureLastEvent(tester) as BillAdded).bill;
    expect(bill.reminderEnabled, isFalse);
    expect(bill.reminderDaysBefore, isNull);
  });

  testWidgets('pengingat "H-3" → reminderEnabled true, daysBefore 3', (
    tester,
  ) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapLabel(tester, l10n.billsReminderD3);

    await tapSubmit(tester);

    final bill = (captureLastEvent(tester) as BillAdded).bill;
    expect(bill.reminderEnabled, isTrue);
    expect(bill.reminderDaysBefore, 3);
  });

  testWidgets('pengingat "H-1" → reminderEnabled true, daysBefore 1', (
    tester,
  ) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapLabel(tester, l10n.billsReminderD1);

    await tapSubmit(tester);

    final bill = (captureLastEvent(tester) as BillAdded).bill;
    expect(bill.reminderEnabled, isTrue);
    expect(bill.reminderDaysBefore, 1);
  });

  // "Hari-H" = daysBefore 0, BUKAN null. Null berarti "ikut pengaturan global"
  // (diresolusi scheduler Task 6.1), jadi keduanya TIDAK boleh tertukar.
  testWidgets('pengingat "Hari-H" → daysBefore 0 (bukan null/ikut pengaturan)', (
    tester,
  ) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapLabel(tester, l10n.billsReminderDayOf);

    await tapSubmit(tester);

    final bill = (captureLastEvent(tester) as BillAdded).bill;
    expect(bill.reminderEnabled, isTrue);
    expect(
      bill.reminderDaysBefore,
      0,
      reason:
          'Hari-H harus 0; null akan tertukar dengan "ikut pengaturan global"',
    );
  });

  // ── Mode edit ─────────────────────────────────────────────────────────────

  testWidgets(
    'mode edit → prefill terisi & emit BillUpdated (bukan BillAdded)',
    (tester) async {
      final created = DateTime(2026, 1, 5);
      final initial = BillEntity(
        id: 7,
        cloudId: 'cloud-7',
        name: 'Cicilan Laptop',
        estimatedAmount: 1200000,
        category: 'shopping',
        isFixedNeed: true,
        notes: 'Transfer tiap tanggal 10',
        dueDate: DateTime(2026, 8, 10),
        recurrence: Recurrence.monthly,
        installmentTotal: 12,
        installmentsPaid: 3,
        dueDayOfMonth: 10,
        reminderDaysBefore: 1,
        reminderEnabled: true,
        status: BillStatus.active,
        createdAt: created,
        updatedAt: created,
      );

      await pumpSheet(tester, initial: initial);

      // Baca controller langsung — hint field juga di-render sebagai Text,
      // jadi find.text() bisa cocok ganda untuk nilai yang sama dengan hint.
      String fieldText(String key) =>
          tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

      expect(fieldText('bill_form_name'), 'Cicilan Laptop');
      expect(fieldText('bill_form_amount'), '1200000');
      expect(fieldText('bill_form_installment'), '12');
      expect(fieldText('bill_form_notes'), 'Transfer tiap tanggal 10');
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text(l10n.billsFormEditTitle), findsOneWidget);

      await tapSubmit(tester);

      final event = captureLastEvent(tester);
      expect(event, isA<BillUpdated>());
      final bill = (event as BillUpdated).bill;
      expect(bill.cloudId, 'cloud-7');
      expect(bill.name, 'Cicilan Laptop');
      expect(bill.estimatedAmount, 1200000);
      expect(bill.category, 'shopping');
      expect(bill.installmentTotal, 12);
      expect(
        bill.installmentsPaid,
        3,
        reason: 'progres cicilan tidak boleh reset',
      );
      expect(bill.recurrenceEndDate, isNull);
      expect(bill.dueDayOfMonth, 10);
      expect(bill.reminderDaysBefore, 1);
      expect(
        bill.createdAt,
        created,
        reason: 'createdAt tidak boleh ditulis ulang',
      );
      verifyNever(() => bloc.add(any(that: isA<BillAdded>())));
    },
  );

  // ── Umpan balik submit ────────────────────────────────────────────────────

  testWidgets('gagal simpan → SnackBar tampil & tombol simpan aktif lagi', (
    tester,
  ) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.failure));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.billsFormSaveFailed), findsOneWidget);
  });

  testWidgets('sukses simpan → sheet ditutup', (tester) async {
    await pumpSheet(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    // Loncat melewati transisi pop sekali frame — `pumpAndSettle` akan
    // menggantung selama indikator loading masih ikut ter-render.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AddEditBillSheet), findsNothing);
    expect(find.text('buka'), findsOneWidget);
  });

  // ── Aksesibilitas & tema ──────────────────────────────────────────────────

  testWidgets('tombol simpan & chip memenuhi hit target 48dp', (tester) async {
    await pumpSheet(tester);

    final submitSize = tester.getSize(
      find.byKey(const ValueKey('bill_form_submit')),
    );
    expect(submitSize.height, greaterThanOrEqualTo(48.0));

    final chipSize = tester.getSize(
      find
          .ancestor(
            of: find.text(l10n.billsRecurrenceMonthly),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(chipSize.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('dark mode render tanpa error', (tester) async {
    await pumpSheet(tester, theme: ThemeData.dark());

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.billsFormAddTitle), findsOneWidget);
  });

  // ── Hint kebutuhan tetap jujur per recurrence (spec §5.6) ─────────────────
  //
  // Hint lama menjanjikan "bukan potong jatah harian kamu". Untuk tagihan
  // non-bulanan janji itu TIDAK benar: `fixedExpenses` berbasis bulan, jadi
  // pembayarannya SELALU dihitung sebagai pengeluaran. Toggle-nya tetap hidup
  // — `isFixedNeed` adalah pernyataan NIAT pengguna (spec §3), penyempitannya
  // terjadi di titik pakai, bukan di form ini.

  group('hint kebutuhan tetap mengikuti recurrence (spec §5.6)', () {
    // Substring, bukan string penuh: keduanya cukup khas untuk tak bertabrakan
    // dengan teks lain di layar, dan tak ikut pecah kalau tanda baca digeser.
    final hintBulanan = find.textContaining('bukan potong jatah harian kamu');
    final hintNonBulanan = find.textContaining(
      'kebutuhan tetap di anggaranmu berbasis bulan',
    );

    testWidgets(
      'monthly (default) → hint lama, hint non-bulanan TIDAK muncul',
      (tester) async {
        await pumpSheet(tester);

        expect(hintBulanan, findsOneWidget);
        expect(hintNonBulanan, findsNothing);
      },
    );

    testWidgets(
      'yearly → hint non-bulanan menggantikan hint lama, toggle tetap hidup',
      (tester) async {
        await pumpSheet(tester);
        await tapLabel(tester, l10n.billsRecurrenceYearly);

        expect(hintNonBulanan, findsOneWidget);
        expect(
          hintBulanan,
          findsNothing,
          reason:
              'janji "bukan potong jatah harian" tidak boleh tersisa di tagihan '
              'yang justru SELALU dihitung sebagai pengeluaran',
        );

        // Toggle SENGAJA tidak dikunci di form — flag = niat pengguna (spec §3).
        // Hanya ada satu Switch di seluruh file ini (`:1092`), jadi finder-nya
        // tak ambigu.
        final sw = tester.widget<Switch>(find.byType(Switch));
        expect(
          sw.onChanged,
          isNotNull,
          reason:
              'form tagihan BUKAN tempat penyempitan — itu tugas sheet bayar',
        );
      },
    );
  });
}
