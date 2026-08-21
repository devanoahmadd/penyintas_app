import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/get_bill_reminder_settings_usecase.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/bills/presentation/pages/bill_form_page.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_category_grid.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/category_bloc.dart';
import 'package:penyintas_app/widgets/common/amount_keypad.dart';
import 'package:penyintas_app/widgets/common/fixed_need_toggle_tile.dart';

class MockBillsBloc extends MockBloc<BillsEvent, BillsState>
    implements BillsBloc {}

class MockCategoryBloc extends MockBloc<CategoryEvent, CategoryState>
    implements CategoryBloc {}

class MockGetBillReminderSettings extends Mock
    implements GetBillReminderSettingsUseCase {}

CategoryEntity _katBawaan({
  required int id,
  required String slug,
  required String labelKey,
  int sortOrder = 10,
}) => CategoryEntity(
  id: id,
  slug: slug,
  labelKey: labelKey,
  isBuiltIn: true,
  isLimitable: true,
  type: 'expense',
  sortOrder: sortOrder,
);

/// Tujuh kategori bawaan + satu `income`, dengan `sortOrder` PERSIS seperti
/// seed produksi (`app_database.dart:522-568`) — termasuk fakta bahwa `fixed`
/// justru paling belakang dan `other` mendahuluinya.
final kategoriBawaan = [
  _katBawaan(id: 1, slug: 'food', labelKey: 'category_food', sortOrder: 0),
  _katBawaan(
    id: 2,
    slug: 'transport',
    labelKey: 'category_transport',
    sortOrder: 1,
  ),
  _katBawaan(
    id: 3,
    slug: 'shopping',
    labelKey: 'category_shopping',
    sortOrder: 2,
  ),
  _katBawaan(id: 4, slug: 'health', labelKey: 'category_health', sortOrder: 3),
  _katBawaan(
    id: 5,
    slug: 'internet',
    labelKey: 'category_internet',
    sortOrder: 4,
  ),
  _katBawaan(id: 7, slug: 'other', labelKey: 'category_other', sortOrder: 5),
  _katBawaan(id: 6, slug: 'fixed', labelKey: 'category_fixed', sortOrder: 6),
  const CategoryEntity(
    id: 9,
    slug: 'income',
    labelKey: 'category_income',
    isBuiltIn: true,
    isLimitable: false,
    type: 'income',
    sortOrder: 7,
  ),
];

BillEntity billContoh({
  int id = 1,
  String name = 'Kos Bu Tini',
  int estimatedAmount = 750000,
  String category = 'fixed',
  bool isFixedNeed = true,
  DateTime? dueDate,
  Recurrence recurrence = Recurrence.monthly,
}) => BillEntity(
  id: id,
  name: name,
  estimatedAmount: estimatedAmount,
  category: category,
  isFixedNeed: isFixedNeed,
  dueDate: dueDate ?? DateTime(2026, 8, 10),
  recurrence: recurrence,
  installmentsPaid: 0,
  reminderEnabled: true,
  status: BillStatus.active,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);

/// Tagihan dengan anchor akhir-bulan yang SEDANG TERPANGKAS.
///
/// `dueDate.day` (28) SENGAJA berbeda dari `dueDayOfMonth` (31), dan 31 tak
/// bisa diturunkan dari nilai mana pun di fixture ini — bukan dari tenor (12),
/// cicilan terbayar (3), pengingat (1), tanggal buat (5), maupun id (7).
/// Aturan independensi fixture: `docs/masalah-produk-tagihan.md` §4.2.
final billAnchorTerpangkas = BillEntity(
  id: 7,
  cloudId: 'cloud-7',
  name: 'Kos Bu Tini',
  estimatedAmount: 1200000,
  category: 'fixed',
  isFixedNeed: true,
  notes: 'Transfer tiap akhir bulan',
  dueDate: DateTime(2026, 2, 28),
  recurrence: Recurrence.monthly,
  installmentTotal: 12,
  installmentsPaid: 3,
  dueDayOfMonth: 31,
  reminderDaysBefore: 1,
  reminderEnabled: true,
  status: BillStatus.active,
  createdAt: DateTime(2026, 1, 5),
  updatedAt: DateTime(2026, 1, 5),
);

/// Tagihan yang kategorinya sudah TERHAPUS — tak ada di [kategoriBawaan].
final billBerkategoriYatim = billContoh(category: 'kursus_bahasa');

/// Tanggal 10, berulang bulanan — sama seperti bawaan [billContoh], tapi
/// diberi nama eksplisit supaya niat test catatan tanggal tak bergantung
/// diam-diam pada nilai bawaan yang bisa berubah demi alasan lain (Task 11).
final billTanggal10Bulanan = billContoh();

/// Berulang tahunan, jatuh tempo 10 Agustus — dipakai menguji catatan
/// tanggal tahunan yang menyebut tanggal DAN nama bulan (Task 11).
final billTahunan = billContoh(recurrence: Recurrence.yearly);

/// Seberapa jauh tepi atas field nominal digulirkan keluar viewport pada test
/// K3. Harus lebih kecil dari SETENGAH tinggi field (minimum 56) supaya titik
/// tengahnya — yang diketuk `tester.tap` — masih berada di dalam viewport.
const _potonganAtas = 16.0;

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
  late MockCategoryBloc categoryBloc;
  late StreamController<CategoryState> categoryController;
  late MockGetBillReminderSettings reminderUsecase;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
    // BillsEvent sealed — pakai event konkret sebagai fallback.
    registerFallbackValue(const BillsSubscribed());
    registerFallbackValue(const LoadCategories());
    registerFallbackValue(const NoParams());
  });

  /// Jawaban langsung dari usecase setelan pengingat global.
  ///
  /// Parameter pertama dipertahankan `null` di semua pemanggil — penundaan
  /// punya stub sendiri di bawah.
  void stubReminderSettings(Duration? tunda, {int daysBefore = 1}) {
    when(() => reminderUsecase(any())).thenAnswer(
      (_) async => Right<Failure, BillReminderSettings>((
        daysBefore: daysBefore,
        hour: 9,
      )),
    );
  }

  /// Menahan jawaban sampai [tiba] diselesaikan test — untuk menguji keadaan
  /// "setelan belum tiba".
  ///
  /// SENGAJA memakai `Completer`, bukan `Future.delayed`. `pumpAndSettle` tak
  /// menyelesaikan timer yang tak menjadwalkan frame, jadi `Future.delayed(1s)`
  /// masih menggantung saat test berakhir dan `flutter_test` menggagalkannya
  /// dengan "A Timer is still pending even after the widget tree was disposed"
  /// — kegagalan yang tak ada hubungannya dengan yang sedang diuji.
  ///
  /// Test WAJIB memanggil `tiba.complete(...)` sebelum selesai.
  void stubReminderSettingsTertunda(Completer<int> tiba) {
    when(() => reminderUsecase(any())).thenAnswer((_) async {
      final daysBefore = await tiba.future;
      return Right<Failure, BillReminderSettings>((
        daysBefore: daysBefore,
        hour: 9,
      ));
    });
  }

  void stubReminderSettingsFailure() {
    when(() => reminderUsecase(any())).thenAnswer(
      (_) async =>
          const Left<Failure, BillReminderSettings>(CacheFailure('db mati')),
    );
  }

  /// Setel keadaan awal `CategoryBloc`. Keadaan berikutnya didorong lewat
  /// [categoryController] — itulah yang membuat jalur PULIH (gagal → retry →
  /// berhasil) bisa dilewati sungguhan, bukan hanya keadaan akhirnya.
  void stubKategori(CategoryState awal) {
    whenListen(categoryBloc, categoryController.stream, initialState: awal);
  }

  void stubCategoriesLoaded() =>
      stubKategori(CategoryLoaded(categories: kategoriBawaan));

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

    categoryBloc = MockCategoryBloc();
    categoryController = StreamController<CategoryState>.broadcast();
    // Bawaan: kategori SUDAH termuat. Test yang menguji jendela memuat/gagal
    // memanggil `stubKategori` sendiri sebelum `pumpPage`.
    stubCategoriesLoaded();

    // `initState` halaman memanggil `sl<GetBillReminderSettingsUseCase>()`,
    // jadi SETIAP test di berkas ini melewatinya — registrasinya harus di
    // `setUp` level berkas, bukan per-test.
    //
    // Pola `unregister-kalau-terdaftar` lalu `registerFactory` meniru
    // `verify_pin_page_test.dart:39-41`. SENGAJA BUKAN `sl.reset()`: reset
    // mengosongkan SELURUH container, termasuk apa pun yang didaftarkan
    // berkas lain, sehingga kegagalan satu test terasa seperti kegagalan
    // berkas.
    reminderUsecase = MockGetBillReminderSettings();
    if (sl.isRegistered<GetBillReminderSettingsUseCase>()) {
      sl.unregister<GetBillReminderSettingsUseCase>();
    }
    sl.registerFactory<GetBillReminderSettingsUseCase>(() => reminderUsecase);
    // Bawaan: setelan tiba seketika dengan nilai global 1 hari sebelum.
    stubReminderSettings(null);
  });

  tearDown(() {
    stateController.close();
    categoryController.close();
    if (sl.isRegistered<GetBillReminderSettingsUseCase>()) {
      sl.unregister<GetBillReminderSettingsUseCase>();
    }
  });

  Widget harness({BillEntity? bill, ThemeData? theme}) => MaterialApp(
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
            // Halaman DIDORONG, bukan dipasang sebagai `home`. Ini bukan
            // sisa dari bentuk sheet — ia yang membuat `Navigator.pop`
            // setelah simpan punya tujuan, dan yang membuat `AppBar`
            // menggambar tombol back sehingga `tester.pageBack()` (T10)
            // bekerja. Aplikasi nyata juga selalu mendorongnya di atas
            // /bills [Audit S1].
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                // TANPA Scaffold pembungkus — BillFormPage bawa sendiri.
                //
                // `.value` untuk KEDUANYA, meski di aplikasi `CategoryBloc`
                // dipasang rute lewat `create`: test yang memiliki mock-nya
                // sendiri harus mengendalikan siklus hidupnya, dan `create`
                // akan menutup mock itu di tengah jalan.
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider<BillsBloc>.value(value: bloc),
                    BlocProvider<CategoryBloc>.value(value: categoryBloc),
                  ],
                  child: BillFormPage(bill: bill),
                ),
              ),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    ),
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    BillEntity? bill,
    ThemeData? theme,
    // [Audit S2] Ukuran bisa ditimpa. Bawaannya layar tinggi supaya form
    // panjang muat tanpa banyak scroll; test yang justru menguji kesempitan
    // (mis. K2 di T9) mengirim ukurannya sendiri. Tanpa parameter ini, test
    // yang menyetel `tester.view.physicalSize` SEBELUM memanggil pumpPage
    // akan ditimpa diam-diam di sini.
    Size ukuran = const Size(600, 2200),
    // Setel `false` saat halaman dibuka dalam keadaan yang memuat indikator
    // berputar (mis. `CategoryLoading` → placeholder grid). `pumpAndSettle`
    // menunggu animasi BERHENTI, dan spinner tak pernah berhenti — jendela
    // memuat justru jadi jendela yang mustahil diuji. Ini bukan detail
    // kosmetik: kebiasaan menyemai `CategoryLoaded` di setUp lahir dari sini,
    // dan bersamanya cacat "sedang memuat terlihat sama dengan sudah
    // terhapus" ikut tak pernah terlihat.
    bool settle = true,
  }) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(bill: bill, theme: theme));
    // Delegate l10n resolve di frame berikutnya — tanpa pump ekstra body
    // MaterialApp belum terbangun sama sekali.
    await tester.pumpAndSettle();
    await tester.tap(find.text('buka'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Cukup untuk menuntaskan transisi rute tanpa menunggu spinner diam.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
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

  /// Ketuk deret digit di panel keypad yang SUDAH terbuka.
  ///
  /// Tombolnya dicari lewat `GestureDetector` terdekat di atas teksnya —
  /// itulah bentuk `_KeyButton` di `amount_keypad.dart`.
  Future<void> ketikDiKeypad(WidgetTester tester, String digit) async {
    for (final d in digit.split('')) {
      await tester.tap(find.widgetWithText(GestureDetector, d).first);
      await tester.pump();
    }
  }

  /// Ketuk backspace keypad [kali] kali.
  ///
  /// Backspace digambar sebagai ikon TANPA teks, jadi dicari lewat label
  /// semantiknya — sekaligus menegaskan label itu memang terpasang.
  Future<void> tapBackspace(WidgetTester tester, {int kali = 1}) async {
    final handle = tester.ensureSemantics();
    final backspace = find.bySemanticsLabel(l10n.commonBackspace);
    for (var i = 0; i < kali; i++) {
      await tester.tap(backspace);
      await tester.pump();
    }
    handle.dispose();
  }

  /// Isi nominal lewat keypad, bukan `enterText`. Field nominal tak lagi
  /// menerima ketikan — ia membuka panel `AmountKeypad`.
  ///
  /// Tak perlu mengosongkan nilai lama lebih dulu: ketukan digit PERTAMA
  /// sesudah panel dibuka mengganti nominal yang ada (lihat grup test
  /// "ketukan pertama").
  Future<void> isiNominal(WidgetTester tester, String digit) async {
    await tapKey(tester, 'bill_form_amount');
    await ketikDiKeypad(tester, digit);
  }

  Future<void> fillBaseFields(
    WidgetTester tester, {
    String name = 'Kos Bu Tini',
    String amount = '750000',
  }) async {
    await tester.enterText(find.byKey(const ValueKey('bill_form_name')), name);
    await tester.pump();
    await isiNominal(tester, amount);
  }

  BillsEvent captureLastEvent(WidgetTester tester) {
    final captured = verify(() => bloc.add(captureAny())).captured;
    return captured.last as BillsEvent;
  }

  // ── (a) Kategori wajib ────────────────────────────────────────────────────

  testWidgets('submit tanpa kategori → tervalidasi, BillAdded TIDAK ter-emit', (
    tester,
  ) async {
    await pumpPage(tester);
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
    await pumpPage(tester);
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
    await pumpPage(tester);
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
    await pumpPage(tester);

    expect(
      tester.widget<Switch>(find.byType(Switch)).value,
      isFalse,
      reason: 'default toggle mati sebelum kategori dipilih',
    );

    await tapLabel(tester, l10n.categoryFixed);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  // Sisi LAIN dari invariant yang sama, dan sisi yang selama ini tak terkunci:
  // "fixed" memberi DEFAULT cerdas, bukan kunci. Tanpa test ini,
  // `_isFixedNeed = slug == 'fixed'` — yang MEMAKSA toggle mati setiap kali
  // kategori lain dipilih — lolos seluruh suite, karena satu-satunya test
  // toggle yang ada hanya pernah menekan "fixed".
  testWidgets('memilih kategori lain tak memaksa toggle kebutuhan tetap mati', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapLabel(tester, l10n.categoryFixed);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tapLabel(tester, l10n.categoryInternet);

    expect(
      tester.widget<Switch>(find.byType(Switch)).value,
      isTrue,
      reason:
          'kategori "fixed" menyalakan toggle SEKALI — pilihan kategori '
          'berikutnya tidak boleh membatalkan niat pengguna',
    );
  });

  // ── (d) Payload BillAdded ─────────────────────────────────────────────────

  testWidgets('BillAdded ter-emit dengan payload yang benar', (tester) async {
    await pumpPage(tester);
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
      await pumpPage(tester);
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
    await pumpPage(tester);
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
    await pumpPage(tester);
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
    await pumpPage(tester);
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
    await pumpPage(tester);
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

  group('chip pengingat (D11, D14)', () {
    testWidgets('chip Bawaan berdiri sendiri, terpisah dari empat chip lain', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(find.text(l10n.billsReminderDefault), findsOneWidget);
      expect(find.text(l10n.billsReminderCustomLabel), findsOneWidget);
      final yBawaan = tester
          .getTopLeft(find.text(l10n.billsReminderDefault))
          .dy;
      final yPemisah = tester
          .getTopLeft(find.text(l10n.billsReminderCustomLabel))
          .dy;
      final yD3 = tester.getTopLeft(find.text(l10n.billsReminderD3)).dy;
      expect(yBawaan, lessThan(yPemisah));
      expect(yPemisah, lessThan(yD3));
    });

    testWidgets('sebelum setelan tiba, chip Bawaan TANPA baris bawah', (
      tester,
    ) async {
      // Penundaan dikendalikan Completer, BUKAN `Future.delayed(1s)` — lihat
      // catatan panjang di `stubReminderSettingsTertunda`.
      final tiba = Completer<int>();
      stubReminderSettingsTertunda(tiba);

      await pumpPage(tester);
      await tester.pump();
      expect(find.text('(${l10n.billsReminderD1})'), findsNothing);

      // Selesaikan sebelum test berakhir supaya tak ada Future menggantung,
      // lalu buktikan barisnya memang MUNCUL setelah datanya tiba — satu test
      // ini jadi mengunci kedua sisi transisinya.
      tiba.complete(1);
      await tester.pumpAndSettle();
      expect(find.text('(${l10n.billsReminderD1})'), findsOneWidget);
    });

    testWidgets('setelan daysBefore=1 → baris bawah "(1 hari sebelum)"', (
      tester,
    ) async {
      stubReminderSettings(null, daysBefore: 1);
      await pumpPage(tester);
      await tester.pumpAndSettle();
      expect(find.text('(${l10n.billsReminderD1})'), findsOneWidget);
    });

    testWidgets('setelan daysBefore=0 → "(Hari itu juga)"', (tester) async {
      stubReminderSettings(null, daysBefore: 0);
      await pumpPage(tester);
      await tester.pumpAndSettle();
      expect(find.text('(${l10n.billsReminderDayOf})'), findsOneWidget);
    });

    testWidgets('setelan daysBefore=5 → kunci berparameter, bukan chip', (
      tester,
    ) async {
      stubReminderSettings(null, daysBefore: 5);
      await pumpPage(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('(${l10n.billsReminderNDaysBefore(5)})'),
        findsOneWidget,
      );
    });

    testWidgets('setelan GAGAL dibaca → chip tetap ada, tanpa baris bawah, '
        'form tetap bisa disimpan', (tester) async {
      stubReminderSettingsFailure();
      await pumpPage(tester);
      await tester.pumpAndSettle();
      expect(find.text(l10n.billsReminderDefault), findsOneWidget);
      // Sisi negatif ini TIDAK lulus vakum: test 'daysBefore=1' di atas
      // membuktikan baris yang sama MUNCUL pada keadaan yang membalikkannya.
      expect(find.text('(${l10n.billsReminderD1})'), findsNothing);
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryFixed);
      await pickDueDate(tester);
      await tapSubmit(tester);
      expect(captureLastEvent(tester), isA<BillAdded>());
    });

    // ── Prefill asinkron vs penjaga buang-perubahan (D15) ─────────────────
    //
    // `_bawaanDaysBefore` tiba SETELAH `initState`, jadi ia tiba setelah
    // `_capAwal` diambil. Form yang tak disentuh siapa pun tidak boleh
    // menyodorkan dialog "Buang perubahan?" hanya karena setelan global
    // menyusul masuk.
    testWidgets('setelan yang tiba setelah initState tak membuat form bersih '
        'terasa berubah', (tester) async {
      final tiba = Completer<int>();
      stubReminderSettingsTertunda(tiba);

      await pumpPage(tester);
      await tester.pump();
      tiba.complete(3);
      await tester.pumpAndSettle();

      // TANPA menyentuh apa pun.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.billsFormDiscardTitle),
        findsNothing,
        reason:
            'pengguna tak boleh dituduh mengubah sesuatu yang tak pernah '
            'ia sentuh',
      );
      expect(find.byType(BillFormPage), findsNothing);
    });

    // ── I5: pemetaan data TIDAK bergeser ──────────────────────────────────

    testWidgets('I5: memilih "Hari itu juga" menyimpan daysBefore=0, '
        'BUKAN null', (tester) async {
      stubReminderSettings(null, daysBefore: 1);
      await pumpPage(tester);
      await tester.pumpAndSettle();
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryFixed);
      await pickDueDate(tester);
      await tapLabel(tester, l10n.billsReminderDayOf);
      await tapSubmit(tester);

      final event = captureLastEvent(tester) as BillAdded;
      expect(event.bill.reminderEnabled, isTrue);
      expect(event.bill.reminderDaysBefore, 0);
    });

    testWidgets('I5: memilih "Bawaan aplikasi" menyimpan daysBefore=null '
        'meski nilai globalnya 1', (tester) async {
      stubReminderSettings(null, daysBefore: 1);
      await pumpPage(tester);
      await tester.pumpAndSettle();
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryFixed);
      await pickDueDate(tester);
      // Berangkat DULU dari Bawaan lalu kembali ke sana: tanpa langkah ini
      // test cuma memeriksa nilai awal `_reminder` dan tak pernah menyentuh
      // kartu Bawaan yang baru disusun ulang task ini.
      await tapLabel(tester, l10n.billsReminderD3);
      await tapLabel(tester, l10n.billsReminderDefault);
      await tapSubmit(tester);

      final event = captureLastEvent(tester) as BillAdded;
      expect(event.bill.reminderEnabled, isTrue);
      expect(
        event.bill.reminderDaysBefore,
        isNull,
        reason: 'Bawaan berarti MEWARISI, bukan menyalin nilainya',
      );
    });

    testWidgets('I5: "Jangan ingatkan" menyimpan enabled=false', (
      tester,
    ) async {
      stubReminderSettings(null, daysBefore: 1);
      await pumpPage(tester);
      await tester.pumpAndSettle();
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryFixed);
      await pickDueDate(tester);
      await tapLabel(tester, l10n.billsReminderOff);
      await tapSubmit(tester);

      final event = captureLastEvent(tester) as BillAdded;
      expect(event.bill.reminderEnabled, isFalse);
    });
  });

  // ── Mode edit ─────────────────────────────────────────────────────────────

  testWidgets(
    'mode edit → prefill terisi & emit BillUpdated (bukan BillAdded)',
    (tester) async {
      final initial = billAnchorTerpangkas;
      final created = initial.createdAt;

      await pumpPage(tester, bill: initial);

      // Baca controller langsung — hint field juga di-render sebagai Text,
      // jadi find.text() bisa cocok ganda untuk nilai yang sama dengan hint.
      String fieldText(String key) =>
          tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

      expect(fieldText('bill_form_name'), 'Kos Bu Tini');
      // Nominal TIDAK lagi `TextField` — ia area tap yang menampilkan nilai
      // sudah terformat. String penuh sengaja dikunci di sini: format Rupiah
      // "Rp 1.245.000" adalah aturan proyek, bukan detail bebas.
      expect(find.text('Rp 1.200.000'), findsOneWidget);
      expect(fieldText('bill_form_installment'), '12');
      expect(fieldText('bill_form_notes'), 'Transfer tiap akhir bulan');
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text(l10n.billsFormEditTitle), findsOneWidget);

      await tapSubmit(tester);

      final event = captureLastEvent(tester);
      expect(event, isA<BillUpdated>());
      final bill = (event as BillUpdated).bill;
      expect(bill.cloudId, 'cloud-7');
      expect(bill.name, 'Kos Bu Tini');
      expect(bill.estimatedAmount, 1200000);
      expect(bill.category, 'fixed');
      expect(bill.installmentTotal, 12);
      expect(
        bill.installmentsPaid,
        3,
        reason: 'progres cicilan tidak boleh reset',
      );
      expect(bill.recurrenceEndDate, isNull);
      expect(
        bill.dueDayOfMonth,
        31,
        reason:
            'anchor akhir-bulan tak boleh diturunkan ulang dari dueDate '
            'yang sedang terpangkas (28 Feb)',
      );
      expect(bill.reminderDaysBefore, 1);
      expect(
        bill.createdAt,
        created,
        reason: 'createdAt tidak boleh ditulis ulang',
      );
      verifyNever(() => bloc.add(any(that: isA<BillAdded>())));
    },
  );

  group('anchor jatuh tempo (§1)', () {
    testWidgets('ubah nominal saja → anchor 31 BERTAHAN', (tester) async {
      await pumpPage(tester, bill: billAnchorTerpangkas);
      await isiNominal(tester, '1500000');
      await tapSubmit(tester);

      final bill = (captureLastEvent(tester) as BillUpdated).bill;
      expect(
        bill.dueDayOfMonth,
        31,
        reason:
            'menyimpan tanpa menyentuh pemilih tanggal tak boleh '
            'menurunkan anchor dari dueDate yang sedang terpangkas',
      );
      expect(bill.dueDate, DateTime(2026, 2, 28));
    });

    testWidgets('pilih tanggal baru 17 Feb → anchor jadi 17', (tester) async {
      await pumpPage(tester, bill: billAnchorTerpangkas);
      await tapKey(tester, 'bill_form_due_date');
      // Kalender terbuka pada Februari 2026 (`initialDate` = `_dueDate` =
      // 28 Feb), jadi yang terpilih adalah 17 FEBRUARI — bukan Maret.
      // Finder dilingkupi ke dialognya: `find.text('17')` telanjang juga
      // menyapu form di baliknya, dan angka polos gampang bertabrakan.
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('17'),
        ),
      );
      await tester.pumpAndSettle();
      await confirmDatePicker(tester);
      await tapSubmit(tester);

      final bill = (captureLastEvent(tester) as BillUpdated).bill;
      expect(bill.dueDayOfMonth, 17);
    });

    testWidgets('mode tambah → anchor diambil dari tanggal yang dipilih', (
      tester,
    ) async {
      await pumpPage(tester);
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryInternet);
      await pickDueDate(tester);
      await tapSubmit(tester);

      final bill = (captureLastEvent(tester) as BillAdded).bill;
      expect(bill.dueDayOfMonth, bill.dueDate.day);
    });

    testWidgets(
      'sekali-jalan (anchor null) dijadikan bulanan → fallback hidup',
      (tester) async {
        final sekaliJalan = billContoh(recurrence: Recurrence.none);
        await pumpPage(tester, bill: sekaliJalan);
        await tapLabel(tester, l10n.billsRecurrenceMonthly);
        await tapSubmit(tester);

        final bill = (captureLastEvent(tester) as BillUpdated).bill;
        expect(bill.dueDayOfMonth, bill.dueDate.day);
      },
    );

    testWidgets('bulanan dijadikan sekali-jalan → anchor jadi null', (
      tester,
    ) async {
      await pumpPage(tester, bill: billAnchorTerpangkas);
      await tapLabel(tester, l10n.billsRecurrenceNone);
      await tapSubmit(tester);

      final bill = (captureLastEvent(tester) as BillUpdated).bill;
      expect(bill.dueDayOfMonth, isNull);
    });

    testWidgets('tahunan: ubah nominal saja → anchor BERTAHAN', (tester) async {
      final tahunan = BillEntity(
        id: 8,
        name: 'Pajak Motor',
        estimatedAmount: 350000,
        category: 'other',
        isFixedNeed: false,
        dueDate: DateTime(2026, 2, 28),
        recurrence: Recurrence.yearly,
        installmentsPaid: 0,
        dueDayOfMonth: 29,
        reminderEnabled: true,
        status: BillStatus.active,
        createdAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 1, 5),
      );
      await pumpPage(tester, bill: tahunan);
      await isiNominal(tester, '400000');
      await tapSubmit(tester);

      final bill = (captureLastEvent(tester) as BillUpdated).bill;
      expect(bill.dueDayOfMonth, 29);
    });

    testWidgets('catatan tanggal menyebut ANCHOR, bukan tanggal terpangkas', (
      tester,
    ) async {
      await pumpPage(tester, bill: billAnchorTerpangkas);

      expect(find.text(l10n.billsFormDueDateMonthlyNote(31)), findsOneWidget);
      expect(
        find.text(l10n.billsFormDueDateMonthlyNote(28)),
        findsNothing,
        reason:
            'catatan yang menyebut 28 berbohong: bulan depan sistem '
            'kembali ke 31',
      );
    });
  });

  // ── Umpan balik submit ────────────────────────────────────────────────────

  /// Bentuk state "gagal tulis" sesudah pemisahan kanal (§2): `status` TETAP
  /// success — itulah yang membuat urutan cabang jadi berbahaya.
  BillsState gagalTulis(BillWriteAction aksi, {int seq = 1}) => BillsState(
    status: BillsStatus.success,
    actionFailure: BillActionFailure(
      aksi: aksi,
      failure: const CacheFailure('db mati'),
      seq: seq,
    ),
  );

  testWidgets('gagal simpan → SnackBar tampil & tombol simpan aktif lagi', (
    tester,
  ) async {
    await pumpPage(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapSubmit(tester);

    stateController.add(gagalTulis(BillWriteAction.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.billsFormSaveFailed), findsOneWidget);
  });

  testWidgets('sukses simpan → halaman ditutup (rute ter-pop)', (tester) async {
    await pumpPage(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapSubmit(tester);

    stateController.add(const BillsState(status: BillsStatus.success));
    await tester.pump();
    // Loncat melewati transisi pop sekali frame — `pumpAndSettle` akan
    // menggantung selama indikator loading masih ikut ter-render.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BillFormPage), findsNothing);
    expect(find.text('buka'), findsOneWidget);
  });

  testWidgets('gagal simpan → snackbar tampil DAN halaman tidak ter-pop', (
    tester,
  ) async {
    await pumpPage(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapSubmit(tester);

    stateController.add(gagalTulis(BillWriteAction.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.billsFormSaveFailed), findsOneWidget);
    expect(
      find.byType(BillFormPage),
      findsOneWidget,
      reason:
          'kegagalan tak boleh menutup halaman — isian pengguna hilang '
          'tanpa jejak kalau ia ter-pop',
    );
    // Asersi di atas TUMPUL sendirian: `pump(300ms)` persis sepanjang transisi
    // pop `MaterialPageRoute`, jadi `BillFormPage` masih ada di pohon tepat
    // saat diperiksa meski pop SUDAH dimulai. Tombol rute di bawah form
    // ('buka', harness) offstage selama form menindihnya sebagai rute opaque,
    // dan langsung onstage begitu pop dimulai — jadi asersi ini menangkap pop
    // SEKETIKA, tanpa bergantung pada durasi transisi sama sekali.
    expect(find.text('buka'), findsNothing);
  });

  testWidgets('sukses simpan → halaman TETAP ter-pop sesudah kanal dipisah', (
    tester,
  ) async {
    await pumpPage(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapSubmit(tester);

    // Sukses TIDAK dipancarkan handler — ia datang sebagai emisi stream
    // daftar. Inilah kenapa `listenWhen` pada `actionFailure` mematikannya.
    stateController.add(
      BillsState(status: BillsStatus.success, bills: [billContoh()]),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BillFormPage), findsNothing);
  });

  testWidgets('gagal → perbaiki → simpan lagi berhasil → halaman menutup', (
    tester,
  ) async {
    await pumpPage(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapSubmit(tester);

    stateController.add(gagalTulis(BillWriteAction.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // SnackBar gagal-simpan menempati sisi bawah layar, PERSIS di atas tombol
    // Simpan. Tunggu ia lewat sendiri dulu — tanpa ini ketukan kedua mengenai
    // snackbar-nya, `_submit()` tak pernah jalan, dan test ini merah karena
    // alasan yang sama sekali bukan yang sedang diuji.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tapSubmit(tester);
    // Bloc membersihkan actionFailure saat stream memancar ulang (§2.7).
    stateController.add(
      BillsState(status: BillsStatus.success, bills: [billContoh()]),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BillFormPage), findsNothing);
  });

  testWidgets('kegagalan simpan LAMA yang masih menggantung tak dibaca ulang', (
    tester,
  ) async {
    // Kegagalan simpan dari kunjungan sebelumnya masih menempel di state
    // bersama saat halaman ini dibuka lagi. Filter `aksi` TIDAK menolongnya —
    // aksinya memang `add`. Yang menolak adalah baseline `seq` yang diambil
    // saat `_submit()`.
    whenListen(
      bloc,
      stateController.stream,
      initialState: gagalTulis(BillWriteAction.add, seq: 4),
    );
    await pumpPage(tester);
    await fillBaseFields(tester);
    await tapLabel(tester, l10n.categoryInternet);
    await pickDueDate(tester);
    await tapSubmit(tester);

    // Emisi apa pun yang menyusul masih membawa galat LAMA itu.
    stateController.add(gagalTulis(BillWriteAction.add, seq: 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(l10n.billsFormSaveFailed),
      findsNothing,
      reason:
          'galat seq 4 sudah ada SEBELUM kiriman ini — ia bukan '
          'jawaban atas Simpan yang baru saja ditekan',
    );
    // SENGAJA TIDAK ada asersi `find.byType(BillFormPage)` di sini. Emisi di
    // atas membawa `status: success`, jadi sesudah baseline `seq` menolaknya
    // sebagai galat, listener JATUH ke cabang sukses dan halaman memang
    // ter-pop — itu "risiko sisa yang diterima sadar" di spec §2.7, bukan
    // bug. Yang diuji test ini adalah baseline `seq`, dan asersi snackbar di
    // atas sudah menguncinya sendirian (sabotase (d) tetap memerah).
  });

  testWidgets(
    'kegagalan milik permukaan LAIN tidak dibaca sebagai gagal simpan',
    (tester) async {
      await pumpPage(tester);
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryInternet);
      await pickDueDate(tester);
      await tapSubmit(tester);

      // Hapus yang gagal di daftar, menggantung di state bersama.
      stateController.add(gagalTulis(BillWriteAction.delete, seq: 9));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(l10n.billsFormSaveFailed),
        findsNothing,
        reason: 'form hanya bertanggung jawab atas add/update',
      );
      // Sama seperti test di atasnya: TIDAK ada asersi
      // `find.byType(BillFormPage)` di sini. Emisi uji membawa
      // `status: success`, jadi sesudah filter `aksi` menolaknya, listener
      // jatuh ke cabang sukses dan halaman memang ter-pop. Menambahkan asersi
      // "halaman masih ada" di sini akan merah — dan yang merah itu benar,
      // bukan bug.
    },
  );

  // ── Kategori datang dari CategoryBloc (Task 8) ────────────────────────────

  ElevatedButton tombolSimpan(WidgetTester tester) => tester
      .widget<ElevatedButton>(find.byKey(const ValueKey('bill_form_submit')));

  // Jendela `CategoryLoading` nyaris tak pernah tergambar di suite widget:
  // kebiasaan menyemai `CategoryLoaded` di setUp membuatnya dilompati, dan
  // cacat "memuat terlihat sama dengan terhapus" ikut tak pernah terlihat.
  // Test ini SENGAJA berhenti di dalam jendela itu.
  testWidgets('CategoryLoading TIDAK menggambar tile yatim', (tester) async {
    stubKategori(const CategoryLoading());
    await pumpPage(tester, bill: billBerkategoriYatim, settle: false);

    expect(
      find.text('Kursus bahasa'),
      findsNothing,
      reason: 'daftar kosong karena sedang memuat BUKAN kategori yang terhapus',
    );
    expect(find.byType(BillCategoryGrid), findsNothing);
  });

  testWidgets(
    'mode ubah × kategori yatim × ubah nominal saja → kategori TERSIMPAN UTUH',
    (tester) async {
      stubCategoriesLoaded();
      await pumpPage(tester, bill: billBerkategoriYatim);
      await isiNominal(tester, '900000');
      await tapSubmit(tester);

      final event = captureLastEvent(tester) as BillUpdated;
      expect(
        event.bill.category,
        'kursus_bahasa',
        reason:
            'kategori yang sudah terhapus tetap milik tagihan ini — mengubah '
            'nominal tak boleh diam-diam mencabutnya',
      );
      expect(event.bill.estimatedAmount, 900000);
    },
  );

  testWidgets('CategoryError menonaktifkan tombol Simpan', (tester) async {
    stubKategori(const CategoryError('gagal'));
    await pumpPage(tester);
    await fillBaseFields(tester);
    await pickDueDate(tester);

    expect(
      tombolSimpan(tester).onPressed,
      isNull,
      reason:
          'menyimpan tagihan tanpa bisa memverifikasi kategorinya adalah '
          'menyimpan tebakan',
    );

    await tapSubmit(tester);
    verifyNever(() => bloc.add(any(that: isA<BillAdded>())));
  });

  testWidgets('CategoryError → retry berhasil → Simpan HIDUP lagi', (
    tester,
  ) async {
    stubKategori(const CategoryError('gagal'));
    await pumpPage(tester);
    await fillBaseFields(tester);
    await pickDueDate(tester);

    await tapKey(tester, 'bill_form_category_retry');
    verify(() => categoryBloc.add(any(that: isA<LoadCategories>()))).called(1);

    categoryController.add(CategoryLoaded(categories: kategoriBawaan));
    await tester.pumpAndSettle();

    expect(find.byType(BillCategoryGrid), findsOneWidget);
    expect(
      tombolSimpan(tester).onPressed,
      isNotNull,
      reason: 'kegagalan yang sudah pulih tak boleh menyandera form',
    );

    await tapLabel(tester, l10n.categoryFixed);
    await tapSubmit(tester);
    expect(captureLastEvent(tester), isA<BillAdded>());
  });

  // ── Keypad nominal & aturan K1–K3 (spec §5.2) ─────────────────────────────

  testWidgets('K1: menyentuh field nominal membuka keypad', (tester) async {
    await pumpPage(tester);
    expect(find.byType(AmountKeypad), findsNothing);
    await tapKey(tester, 'bill_form_amount');
    expect(find.byType(AmountKeypad), findsOneWidget);
  });

  testWidgets('K1: memfokuskan field nama MENUTUP keypad', (tester) async {
    await pumpPage(tester);
    await tapKey(tester, 'bill_form_amount');
    expect(find.byType(AmountKeypad), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bill_form_name')));
    await tester.pumpAndSettle();
    expect(find.byType(AmountKeypad), findsNothing);
  });

  testWidgets('K1: membuka keypad melepas fokus field teks', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('bill_form_name')));
    await tester.pumpAndSettle();
    expect(
      tester.testTextInput.isRegistered && tester.testTextInput.isVisible,
      isTrue,
    );

    await tapKey(tester, 'bill_form_amount');
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('K2: tombol Simpan tetap terlihat saat keypad terbuka', (
    tester,
  ) async {
    // [Audit S2] Ukuran dikirim LEWAT pumpPage. Menyetel
    // `tester.view.physicalSize` sebelum memanggilnya percuma — pumpPage
    // menimpanya dengan 600×2200, dan test ini justru ada untuk menguji
    // layar SEMPIT tempat keypad, Simpan, dan isi form berebut ruang.
    await pumpPage(tester, ukuran: const Size(400, 800));
    await tapKey(tester, 'bill_form_amount');
    await tester.pumpAndSettle();

    final tombol = find.byKey(const ValueKey('bill_form_submit'));
    final keypad = find.byType(AmountKeypad);
    expect(tombol, findsOneWidget);
    expect(
      tester.getBottomLeft(tombol).dy,
      lessThanOrEqualTo(tester.getTopLeft(keypad).dy + 1),
      reason: 'Simpan harus di ATAS panel keypad, bukan tertutup olehnya',
    );
  });

  testWidgets('K3: membuka keypad menarik field nominal ke area terlihat', (
    tester,
  ) async {
    await pumpPage(tester, ukuran: const Size(400, 800));

    final area = find.byType(SingleChildScrollView);
    final field = find.byKey(const ValueKey('bill_form_amount'));
    final atasViewport = tester.getTopLeft(area).dy;

    // Prasyarat: gulirkan form sampai tepi ATAS field nominal terpotong
    // keluar viewport — persis keadaan pengguna yang menggulir ke bawah lalu
    // berubah pikiran dan menyentuh sisa field yang masih terlihat.
    // `jumpTo`, bukan `drag`: drag menyisakan touch-slop yang membuat jarak
    // gulirnya tak persis, dan prasyarat ini bergantung pada angka persis.
    //
    // Diambil dari field nominal, bukan `find.byType(Scrollable)`: grid
    // kategori juga sebuah Scrollable dan hidup di dalam area gulir yang sama.
    final gulir = Scrollable.of(tester.element(field));
    gulir.position.jumpTo(
      tester.getTopLeft(field).dy - atasViewport + _potonganAtas,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(field).dy,
      lessThan(atasViewport),
      reason: 'prasyarat gagal: field belum terpotong, test ini jadi kosong',
    );

    // Ketuk LANGSUNG — bukan lewat `tapKey`, yang meng-ensureVisible duluan
    // dan justru menghapus prasyarat di atas.
    await tester.tap(field);
    await tester.pumpAndSettle();

    expect(find.byType(AmountKeypad), findsOneWidget);
    expect(
      tester.getTopLeft(field).dy,
      greaterThanOrEqualTo(atasViewport),
      reason:
          'K3: membuka keypad harus menggulirkan field nominal kembali ke '
          'area yang terlihat, bukan meninggalkannya terpotong',
    );
  });

  testWidgets('nominal dari keypad sampai ke LAYAR dan ke payload simpan', (
    tester,
  ) async {
    await pumpPage(tester);
    // SENGAJA bukan 750.000. Placeholder field ini dirender sebagai
    // "Rp 750.000" juga, jadi asersi layar dengan angka itu tetap hijau
    // walau ketukan keypad tak pernah sampai ke layar — asersinya kosong.
    await fillBaseFields(tester, amount: '480000');

    expect(
      find.text('Rp 480.000'),
      findsOneWidget,
      reason:
          'tiap ketukan keypad wajib punya jalur rebuild — tanpa itu pengguna '
          'menekan angka dan fieldnya diam saja',
    );

    await tapLabel(tester, l10n.categoryFixed);
    await pickDueDate(tester);
    await tapSubmit(tester);

    final event = captureLastEvent(tester) as BillAdded;
    expect(event.bill.estimatedAmount, 480000);
  });

  testWidgets('field "Berapa kali?" TETAP memakai keyboard sistem, '
      'bukan keypad', (tester) async {
    await pumpPage(tester);
    await tapLabel(tester, l10n.billsRecurrenceMonthly);
    await tapLabel(tester, l10n.billsTenorCount);
    await tester.enterText(
      find.byKey(const ValueKey('bill_form_installment')),
      '12',
    );
    await tester.pump();
    expect(find.byType(AmountKeypad), findsNothing);
  });

  // Satu-satunya jalan keluar eksplisit dari panel (gerbang ui-ux-pro-max:
  // `escape-routes` + `gesture-alternative`). Tanpa ini, menutup keypad hanya
  // bisa lewat efek samping — menyentuh field teks lain.
  testWidgets('tombol Selesai menutup panel keypad', (tester) async {
    await pumpPage(tester);
    await tapKey(tester, 'bill_form_amount');
    expect(find.byType(AmountKeypad), findsOneWidget);

    await tapKey(tester, 'bill_form_keypad_done');
    expect(find.byType(AmountKeypad), findsNothing);
  });

  // `AmountKeypad` menurunkan TINGGI tombol dari `horizontalPadding` yang
  // dikirim pemanggil [Audit S3]. Kalau padding panel di halaman ini digeser
  // tanpa menggeser nilai itu, tombolnya menyusut di bawah 48dp tanpa satu
  // pun error — persis jenis kerusakan yang tak terlihat mata.
  testWidgets('tombol keypad memenuhi hit target 48dp di layar sempit', (
    tester,
  ) async {
    await pumpPage(tester, ukuran: const Size(400, 800));
    await tapKey(tester, 'bill_form_amount');

    final tombol = find.widgetWithText(GestureDetector, '7').first;
    expect(
      tester.getSize(tombol).height,
      greaterThanOrEqualTo(48.0),
      reason:
          'padding panel dan `horizontalPadding` AmountKeypad harus tetap '
          'sinkron — kalau tidak, tinggi tombol jatuh diam-diam',
    );
  });

  // Lanskap & mode jendela kecil: badan halaman bisa lebih pendek daripada
  // panel + bilah Simpan. Tanpa batas tinggi panel, Column body meluap — 69px
  // pada 800×360 saat aturan ini pertama ditulis, lengkap dengan garis
  // kuning-hitam di layar pengguna.
  testWidgets('panel keypad tak meluap di layar lanskap pendek', (
    tester,
  ) async {
    await pumpPage(tester, ukuran: const Size(800, 360));
    await tapKey(tester, 'bill_form_amount');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AmountKeypad), findsOneWidget);
    // K2 tak boleh dikorbankan demi muat.
    expect(
      tester.getBottomLeft(find.byKey(const ValueKey('bill_form_submit'))).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(AmountKeypad)).dy + 1),
      reason: 'Simpan tetap di ATAS panel, juga saat panel dipepet',
    );
  });

  // Field tanpa caret gampang jadi jebakan aksesibilitas: `excludeSemantics`
  // di simpul pembungkus MEMBUANG aksi ketuk milik InkWell di bawahnya. Jari
  // tetap bisa mengetuknya dan widget test tetap hijau — yang hilang cuma
  // kemampuan pembaca layar mengaktifkannya.
  testWidgets('field nominal tetap tombol yang bisa diaktifkan pembaca layar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPage(tester);
    final field = find.byKey(const ValueKey('bill_form_amount'));

    expect(
      tester.getSemantics(field),
      // `isSemantics`, bukan `matchesSemantics`: yang pertama hanya memeriksa
      // yang disebut, yang kedua menuntut SELURUH flag cocok.
      isSemantics(
        isButton: true,
        hasTapAction: true,
        label: l10n.billsFormAmountLabel,
        // Placeholder mendarat di `hint`, dan `value` MASIH KOSONG. Kalau
        // placeholder diumumkan sebagai `value`, form kosong terdengar persis
        // sama dengan form berisi Rp 750.000 — dan `TextField` lama tidak
        // pernah begitu.
        hint: 'Rp 750.000',
        value: '',
      ),
    );

    await isiNominal(tester, '480000');

    expect(
      tester.getSemantics(field),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        label: l10n.billsFormAmountLabel,
        hint: '',
        value: 'Rp 480.000',
      ),
    );
    handle.dispose();
  });

  // ── Ketukan pertama sesudah panel dibuka (mode ubah) ──────────────────────

  testWidgets('ketukan digit pertama MENGGANTI nominal lama, bukan menambah', (
    tester,
  ) async {
    await pumpPage(tester, bill: billContoh(estimatedAmount: 1245000));
    expect(find.text('Rp 1.245.000'), findsOneWidget);

    await tapKey(tester, 'bill_form_amount');
    await ketikDiKeypad(tester, '7');
    expect(
      find.text('Rp 7'),
      findsOneWidget,
      reason:
          'membuka Rp 1.245.000 lalu menekan "7" berarti menulis ulang, '
          'bukan membuat Rp 12.450.007',
    );

    // Ketukan berikutnya menambah seperti biasa.
    await ketikDiKeypad(tester, '50');
    expect(find.text('Rp 750'), findsOneWidget);
  });

  testWidgets('backspace pada ketukan pertama tetap backspace biasa', (
    tester,
  ) async {
    await pumpPage(tester, bill: billContoh(estimatedAmount: 1245000));
    await tapKey(tester, 'bill_form_amount');

    await tapBackspace(tester);
    expect(
      find.text('Rp 124.500'),
      findsOneWidget,
      reason: 'backspace menghapus satu digit — ia tidak mengosongkan semuanya',
    );

    // …dan sesudah backspace, digit menambah: pengguna jelas sedang menyunting
    // angka yang ada, bukan menulis angka baru.
    await ketikDiKeypad(tester, '7');
    expect(find.text('Rp 1.245.007'), findsOneWidget);
  });

  // Sisi SEBALIKNYA dari test di bawah, dan sisi yang lebih gampang jebol:
  // field nominal tetap tombol hidup selagi panel terbuka, jadi ia bisa
  // disentuh lagi tanpa panel pernah tertutup. Itu BUKAN transisi
  // tertutup → terbuka — dan tak ada satu piksel pun di layar yang berubah
  // saat itu terjadi (border sudah aktif sebelum dan sesudah), jadi kalau
  // penandanya ikut menyala ulang, angka yang sudah diketik hilang tanpa
  // pengguna tahu kenapa.
  testWidgets('menyentuh field saat panel SUDAH terbuka tak mengulang aturan '
      'ketukan pertama', (tester) async {
    await pumpPage(tester, bill: billContoh(estimatedAmount: 1245000));

    await tapKey(tester, 'bill_form_amount');
    // Angka SENGAJA bukan turunan 750.000 — placeholder field ini dirender
    // sebagai "Rp 750.000", dan asersi yang bertabrakan dengannya hijau
    // walau nilainya tak pernah berubah.
    await ketikDiKeypad(tester, '48');
    expect(find.text('Rp 48'), findsOneWidget);

    // Sentuh lagi TANPA menutup panel lebih dulu.
    await tapKey(tester, 'bill_form_amount');
    await ketikDiKeypad(tester, '0');

    expect(
      find.text('Rp 480'),
      findsOneWidget,
      reason:
          'sentuhan pada panel yang sudah terbuka bukan pembukaan baru — '
          'digit sesudahnya harus MENAMBAH, bukan mengganti jadi Rp 0',
    );
  });

  testWidgets('tutup lalu buka lagi mengulang aturan ketukan pertama', (
    tester,
  ) async {
    await pumpPage(tester, bill: billContoh(estimatedAmount: 1245000));

    await tapKey(tester, 'bill_form_amount');
    await ketikDiKeypad(tester, '7');
    expect(find.text('Rp 7'), findsOneWidget);

    await tapKey(tester, 'bill_form_keypad_done');
    await tapKey(tester, 'bill_form_amount');
    await ketikDiKeypad(tester, '8');

    expect(
      find.text('Rp 8'),
      findsOneWidget,
      reason:
          'aturan berlaku tiap kali panel berpindah dari tertutup ke terbuka, '
          'bukan sekali seumur halaman',
    );
  });

  // ── Aksesibilitas & tema ──────────────────────────────────────────────────

  testWidgets('tombol simpan & chip memenuhi hit target 48dp', (tester) async {
    await pumpPage(tester);

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
    await pumpPage(tester, theme: ThemeData.dark());

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
        await pumpPage(tester);

        expect(hintBulanan, findsOneWidget);
        expect(hintNonBulanan, findsNothing);
      },
    );

    testWidgets(
      'yearly → hint non-bulanan menggantikan hint lama, toggle tetap hidup',
      (tester) async {
        await pumpPage(tester);
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
        // Hanya ada satu Switch di seluruh halaman (di `FixedNeedToggleTile`),
        // jadi finder-nya tak ambigu.
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

  // ── (?) sheet penjelasan kebutuhan tetap (Task 15) ────────────────────────

  group('(?) kebutuhan tetap di form', () {
    testWidgets('(?) di form membuka sheet penjelasan', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text(l10n.billsFixedHelpTitle), findsOneWidget);
    });

    testWidgets('menekan (?) TIDAK membalik toggle kebutuhan tetap', (
      tester,
    ) async {
      await pumpPage(tester);
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryFood);
      await pickDueDate(tester);
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text(l10n.billsFixedHelpTitle))).pop();
      await tester.pumpAndSettle();
      await tapSubmit(tester);

      final event = captureLastEvent(tester) as BillAdded;
      expect(event.bill.isFixedNeed, isFalse);
    });

    // I4 — toggle di FORM tidak pernah dikunci. Sabotase: `enabled: false`
    // pada `FixedNeedToggleTile` di form.
    testWidgets('I4: toggle kebutuhan tetap di form selalu bisa diubah', (
      tester,
    ) async {
      await pumpPage(tester, bill: billTahunan);
      final sw = tester.widget<Switch>(
        find.descendant(
          of: find.byType(FixedNeedToggleTile),
          matching: find.byType(Switch),
        ),
      );
      expect(
        sw.onChanged,
        isNotNull,
        reason: 'penyempitan terjadi di sheet bayar, bukan di form',
      );
    });
  });

  // ── PopScope — buang perubahan (D15) ──────────────────────────────────────
  //
  // `tester.pageBack()` MUSTAHIL bekerja di harness ini: ia mencari
  // `find.byTooltip('Back')` yang dipatok keras bahasa Inggris
  // (`flutter_test/lib/src/widget_tester.dart:1170`), sedangkan tooltip
  // lokal `id` adalah 'Kembali'. `tester.tap(find.byType(BackButton))`
  // dipakai sebagai gantinya — `BackButton` memanggil `Navigator.maybePop()`,
  // yang justru menghormati `PopScope.canPop`.
  group('PopScope — buang perubahan (D15)', () {
    Future<void> tekanBack(WidgetTester tester) async {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }

    testWidgets('form bersih: back langsung menutup, tanpa dialog', (
      tester,
    ) async {
      await pumpPage(tester);
      await tekanBack(tester);
      expect(find.text(l10n.billsFormDiscardTitle), findsNothing);
      expect(find.byType(BillFormPage), findsNothing);
    });

    testWidgets('form berubah: back MENAHAN dan memunculkan dialog', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.enterText(
        find.byKey(const ValueKey('bill_form_name')),
        'Kos Bu Tini',
      );
      await tester.pump();
      await tekanBack(tester);
      expect(find.text(l10n.billsFormDiscardTitle), findsOneWidget);
      expect(find.byType(BillFormPage), findsOneWidget);
    });

    testWidgets('"Lanjut mengisi" mengembalikan ke form', (tester) async {
      await pumpPage(tester);
      await tester.enterText(
        find.byKey(const ValueKey('bill_form_name')),
        'Kos',
      );
      await tester.pump();
      await tekanBack(tester);
      await tester.tap(find.text(l10n.billsFormDiscardCancel));
      await tester.pumpAndSettle();
      expect(find.byType(BillFormPage), findsOneWidget);
      expect(
        find.text('Kos'),
        findsOneWidget,
        reason: 'isian tak boleh hilang saat pengguna memilih bertahan',
      );
    });

    testWidgets('"Buang" menutup form', (tester) async {
      await pumpPage(tester);
      await tester.enterText(
        find.byKey(const ValueKey('bill_form_name')),
        'Kos',
      );
      await tester.pump();
      await tekanBack(tester);
      await tester.tap(find.text(l10n.billsFormDiscardConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(BillFormPage), findsNothing);
    });

    testWidgets('isi lalu KOSONGKAN lagi BUKAN perubahan — tanpa dialog', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.enterText(
        find.byKey(const ValueKey('bill_form_name')),
        'Kos',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('bill_form_name')), '');
      await tester.pump();
      await tekanBack(tester);
      expect(find.text(l10n.billsFormDiscardTitle), findsNothing);
    });

    testWidgets('mode ubah tanpa menyentuh apa pun BUKAN perubahan', (
      tester,
    ) async {
      await pumpPage(tester, bill: billContoh());
      await tekanBack(tester);
      expect(find.text(l10n.billsFormDiscardTitle), findsNothing);
    });

    testWidgets('mode ubah, nilai dikembalikan ke asal BUKAN perubahan', (
      tester,
    ) async {
      final bill = billContoh();
      await pumpPage(tester, bill: bill);
      await tester.enterText(
        find.byKey(const ValueKey('bill_form_name')),
        'Berubah',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('bill_form_name')),
        bill.name,
      );
      await tester.pump();
      await tekanBack(tester);
      expect(find.text(l10n.billsFormDiscardTitle), findsNothing);
    });

    testWidgets('setelah Simpan, pop TIDAK memicu dialog', (tester) async {
      await pumpPage(tester);
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryFixed);
      await pickDueDate(tester);
      await tapSubmit(tester);

      stateController.add(const BillsState(status: BillsStatus.success));
      await tester.pump();
      // Loncat melewati transisi pop sekali frame — `pumpAndSettle` akan
      // menggantung selama indikator loading masih ikut ter-render.
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(l10n.billsFormDiscardTitle), findsNothing);
      expect(find.byType(BillFormPage), findsNothing);
    });

    // ── [Audit B3] Catatan ikut dijaga ──────────────────────────────────
    //
    // Test ini merah tanpa `onChanged: setState(() {})` di field catatan,
    // dan tujuh test di atas tetap hijau tanpanya — itulah kenapa ia perlu
    // berdiri sendiri.
    testWidgets('mengetik HANYA di Catatan tetap dihitung sebagai perubahan', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.enterText(
        find.byKey(const ValueKey('bill_form_notes')),
        'Transfer lewat BCA, jangan lupa simpan struk',
      );
      await tester.pump();
      await tekanBack(tester);
      expect(
        find.text(l10n.billsFormDiscardTitle),
        findsOneWidget,
        reason: 'catatan panjang adalah isian yang paling mahal kalau hilang',
      );
    });

    testWidgets('catatan yang dikembalikan kosong BUKAN perubahan', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.enterText(
        find.byKey(const ValueKey('bill_form_notes')),
        'coba',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('bill_form_notes')), '');
      await tester.pump();
      await tekanBack(tester);
      expect(find.text(l10n.billsFormDiscardTitle), findsNothing);
    });

    // ── Panel keypad terbuka dilipat dulu ─────────────────────────────────
    //
    // Bukan bagian dari daftar 10 test asli — tapi brief task ini eksplisit
    // menandainya sebagai bagian dari task, bukan bonus: tanpa penjaga ini,
    // pengguna yang cuma ingin menutup panel keypad ditawari "Buang
    // perubahan?" untuk nominal yang justru baru saja ia ketik dengan
    // sengaja.
    testWidgets(
      'keypad terbuka: back pertama melipat panel, back kedua baru menawarkan buang',
      (tester) async {
        await pumpPage(tester);
        await isiNominal(tester, '480000');
        expect(find.byType(AmountKeypad), findsOneWidget);

        await tekanBack(tester);
        expect(
          find.byType(AmountKeypad),
          findsNothing,
          reason: 'back pertama melipat panel — bukan menawarkan buang',
        );
        expect(find.text(l10n.billsFormDiscardTitle), findsNothing);
        expect(find.byType(BillFormPage), findsOneWidget);

        await tekanBack(tester);
        expect(
          find.text(l10n.billsFormDiscardTitle),
          findsOneWidget,
          reason:
              'back kedua, dengan panel sudah tertutup, baru menanyakan buang',
        );
      },
    );

    // ── Back selagi menyimpan [Important 1, review T10 ronde 1] ──────────
    //
    // Sebelum perbaikan ini, `_isSubmitting` ikut membuka kunci `canPop`,
    // jadi back di sini mem-pop halaman SEKETIKA — state ter-dispose sebelum
    // BLoC sempat menjawab, dan jawaban gagal-simpan (snackbar) tak pernah
    // sampai ke layar. Test ini membuktikan KEDUA sisi: back ditelan (bukan
    // menutup halaman, bukan menawarkan dialog buang), DAN jawaban BLoC yang
    // menyusul tetap sampai.
    testWidgets('tekan back selagi menyimpan: back ditelan, gagal-simpan tetap '
        'sampai ke layar', (tester) async {
      await pumpPage(tester);
      await fillBaseFields(tester);
      await tapLabel(tester, l10n.categoryFixed);
      await pickDueDate(tester);
      await tapSubmit(tester);

      // Back SEBELUM BLoC menjawab — lihat komentar grup di atas.
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      // Lompati transisi pop kalau-kalau back tadi (secara keliru) tetap
      // memulainya — `pumpAndSettle` akan menggantung selama indikator
      // loading masih ikut ter-render.
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text(l10n.billsFormDiscardTitle),
        findsNothing,
        reason: 'back selagi menyimpan ditelan diam-diam, bukan ditanya',
      );
      expect(
        find.byType(BillFormPage),
        findsOneWidget,
        reason: 'halaman tak boleh ter-pop di tengah proses simpan',
      );

      // BLoC baru menjawab GAGAL setelah back tadi ditelan.
      stateController.add(gagalTulis(BillWriteAction.add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(l10n.billsFormSaveFailed),
        findsOneWidget,
        reason:
            'kalau back tadi sempat mem-pop halaman, BlocListener sudah '
            'mati dan snackbar ini tak akan pernah tampil',
      );
    });
  });

  // ── Catatan bersyarat: tanggal jatuh tempo & tenor (Task 11) ─────────────
  group('catatan bersyarat di bawah tanggal', () {
    testWidgets('bulanan → catatan menyebut tanggal berapa tiap bulan', (
      tester,
    ) async {
      await pumpPage(tester, bill: billTanggal10Bulanan);
      expect(find.text(l10n.billsFormDueDateMonthlyNote(10)), findsOneWidget);
    });

    testWidgets('tahunan → catatan menyebut tanggal DAN nama bulan', (
      tester,
    ) async {
      await pumpPage(tester, bill: billTahunan);
      expect(
        find.text(l10n.billsFormDueDateYearlyNote(10, 'Agustus')),
        findsOneWidget,
      );
    });

    testWidgets('sekali-jalan → TIDAK ada catatan tanggal sama sekali', (
      tester,
    ) async {
      await pumpPage(
        tester,
        bill: billTanggal10Bulanan.copyWith(recurrence: Recurrence.none),
      );
      expect(find.text(l10n.billsFormDueDateMonthlyNote(10)), findsNothing);
      expect(find.textContaining('tiap tahun'), findsNothing);
    });

    testWidgets('tanggal belum dipilih → tak ada catatan meski bulanan', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(find.textContaining('tiap bulan'), findsNothing);
    });

    testWidgets('mengganti pengulangan mengganti catatannya', (tester) async {
      await pumpPage(tester, bill: billTanggal10Bulanan);
      expect(find.text(l10n.billsFormDueDateMonthlyNote(10)), findsOneWidget);
      await tapLabel(tester, l10n.billsRecurrenceYearly);
      expect(find.text(l10n.billsFormDueDateMonthlyNote(10)), findsNothing);
      expect(find.textContaining('tiap tahun'), findsOneWidget);
    });
  });

  group('catatan chip tenor', () {
    testWidgets('"Tanpa batas" terpilih → catatannya yang tampil', (
      tester,
    ) async {
      await pumpPage(tester, bill: billTanggal10Bulanan);
      expect(find.text(l10n.billsTenorUnlimitedNote), findsOneWidget);
      expect(find.text(l10n.billsTenorCountNote), findsNothing);
    });

    testWidgets('pindah ke "Jumlahnya pasti" mengganti catatannya', (
      tester,
    ) async {
      await pumpPage(tester, bill: billTanggal10Bulanan);
      await tapLabel(tester, l10n.billsTenorCount);
      expect(find.text(l10n.billsTenorCountNote), findsOneWidget);
      expect(find.text(l10n.billsTenorUnlimitedNote), findsNothing);
    });

    // [Review T11 ronde 1] Cabang `endDate` bersebelahan & mirip secara
    // sintaksis dengan cabang `count` di produksi — tanpa test arah "muncul"
    // ini, keduanya bisa tertukar (mis. `endDate` salah dipetakan ke
    // `billsTenorCountNote`) tanpa satu pun test yang merah.
    testWidgets('pindah ke "Tanggalnya pasti" mengganti catatannya', (
      tester,
    ) async {
      await pumpPage(tester, bill: billTanggal10Bulanan);
      await tapLabel(tester, l10n.billsTenorEndDate);
      expect(find.text(l10n.billsTenorEndDateNote), findsOneWidget);
      expect(find.text(l10n.billsTenorUnlimitedNote), findsNothing);
      expect(find.text(l10n.billsTenorCountNote), findsNothing);
    });

    testWidgets('sekali-jalan menyembunyikan seluruh blok tenor '
        'beserta catatannya', (tester) async {
      await pumpPage(tester, bill: billTanggal10Bulanan);
      await tapLabel(tester, l10n.billsRecurrenceNone);
      expect(find.text(l10n.billsTenorUnlimitedNote), findsNothing);
      expect(find.text(l10n.billsTenorCountNote), findsNothing);
      expect(find.text(l10n.billsTenorEndDateNote), findsNothing);
    });
  });
}
