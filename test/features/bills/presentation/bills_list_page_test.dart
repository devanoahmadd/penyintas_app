import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/routing/app_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/get_bill_reminder_settings_usecase.dart';
import 'package:penyintas_app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:penyintas_app/features/bills/presentation/pages/bill_form_page.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_item.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/category_bloc.dart';

class MockBillsBloc extends MockBloc<BillsEvent, BillsState>
    implements BillsBloc {}

class MockCategoryBloc extends MockBloc<CategoryEvent, CategoryState>
    implements CategoryBloc {}

class MockGetBillReminderSettings extends Mock
    implements GetBillReminderSettingsUseCase {}

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
  late MockCategoryBloc categoryBloc;
  late MockGetBillReminderSettings reminderUsecase;

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  // Diangkat dari dalam `group('snackbar undo')` (Task 5, §2.6) — dipakai
  // juga oleh grup kanal galat tulis dan test presedensi. Diangkat, bukan
  // disalin: dua fixture kembar yang bisa menyimpang diam-diam adalah bug
  // test yang sulit terlihat.
  final snapshotUndo = UndoSnapshot(
    billId: 7,
    dueDate: todayStart.subtract(const Duration(days: 30)),
    installmentsPaid: 3,
    status: BillStatus.active,
    txId: 'tx-abc',
  );

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

  // ── Fixture kategori (A.1 dari perkakas test bersama) ─────────────────────
  //
  // `sortOrder` di bawah MENIRU seed produksi (`app_database.dart:522-568`) —
  // termasuk fakta bahwa `fixed` justru paling belakang dan `other`
  // mendahuluinya.
  CategoryEntity katBawaan({
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

  CategoryEntity katKustom({
    required String slug,
    String? iconSlug,
    String labelOverride = 'Kategori Kustom',
    int id = 50,
    int sortOrder = 100,
  }) => CategoryEntity(
    id: id,
    slug: slug,
    labelOverride: labelOverride,
    isBuiltIn: false,
    isLimitable: true,
    type: 'expense',
    sortOrder: sortOrder,
    iconSlug: iconSlug,
  );

  /// Tujuh kategori bawaan + satu `income`, dengan `sortOrder` PERSIS seperti
  /// seed produksi.
  final kategoriBawaan = [
    katBawaan(id: 1, slug: 'food', labelKey: 'category_food', sortOrder: 0),
    katBawaan(
      id: 2,
      slug: 'transport',
      labelKey: 'category_transport',
      sortOrder: 1,
    ),
    katBawaan(
      id: 3,
      slug: 'shopping',
      labelKey: 'category_shopping',
      sortOrder: 2,
    ),
    katBawaan(id: 4, slug: 'health', labelKey: 'category_health', sortOrder: 3),
    katBawaan(
      id: 5,
      slug: 'internet',
      labelKey: 'category_internet',
      sortOrder: 4,
    ),
    katBawaan(id: 7, slug: 'other', labelKey: 'category_other', sortOrder: 5),
    katBawaan(id: 6, slug: 'fixed', labelKey: 'category_fixed', sortOrder: 6),
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

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
    registerFallbackValue(const NoParams());
    // `any(that: isA<BillDeleted>())` di grup dialog hapus butuh fallback
    // bertipe BillsEvent — tanpa ini mocktail melempar dan meninggalkan
    // matcher-nya kotor, yang lalu merusak stubbing test-test SESUDAHNYA.
    registerFallbackValue(const BillsSubscribed());
  });

  setUp(() {
    bloc = MockBillsBloc();
    categoryBloc = MockCategoryBloc();
    // `buildBillsRoute()` memasang CategoryBloc di ketiga node rute — jadi
    // tiruannya wajib ada supaya `sl<CategoryBloc>()` tidak melempar saat
    // rute dibangun.
    //
    // Keadaan awalnya WAJIB `CategoryLoaded` sejak grid kategori masuk ke
    // form (Task 8). `CategoryInitial` membuat form menggambar placeholder
    // berisi indikator berputar, dan `pumpAndSettle` di test navigasi
    // menunggu putaran itu berhenti selamanya.
    whenListen(
      categoryBloc,
      const Stream<CategoryState>.empty(),
      initialState: const CategoryLoaded(
        categories: [
          CategoryEntity(
            id: 6,
            slug: 'fixed',
            labelKey: 'category_fixed',
            isBuiltIn: true,
            isLimitable: true,
            type: 'expense',
            sortOrder: 6,
          ),
          CategoryEntity(
            id: 5,
            slug: 'internet',
            labelKey: 'category_internet',
            isBuiltIn: true,
            isLimitable: true,
            type: 'expense',
            sortOrder: 4,
          ),
        ],
      ),
    );

    // Rute NYATA yang dipakai harness membaca kedua bloc dari GetIt.
    if (sl.isRegistered<BillsBloc>()) sl.unregister<BillsBloc>();
    if (sl.isRegistered<CategoryBloc>()) sl.unregister<CategoryBloc>();
    sl.registerFactory<BillsBloc>(() => bloc);
    sl.registerFactory<CategoryBloc>(() => categoryBloc);

    // Test navigasi di berkas ini benar-benar mendorong `BillFormPage`, dan
    // sejak T12 `initState`-nya membaca setelan pengingat global lewat
    // GetIt — tanpa tiruan ini rutenya melempar sebelum satu asersi pun
    // berjalan.
    reminderUsecase = MockGetBillReminderSettings();
    if (sl.isRegistered<GetBillReminderSettingsUseCase>()) {
      sl.unregister<GetBillReminderSettingsUseCase>();
    }
    sl.registerFactory<GetBillReminderSettingsUseCase>(() => reminderUsecase);
    when(() => reminderUsecase(any())).thenAnswer(
      (_) async =>
          const Right<Failure, BillReminderSettings>((daysBefore: 1, hour: 9)),
    );
  });

  tearDown(() {
    if (sl.isRegistered<BillsBloc>()) sl.unregister<BillsBloc>();
    if (sl.isRegistered<CategoryBloc>()) sl.unregister<CategoryBloc>();
    if (sl.isRegistered<GetBillReminderSettingsUseCase>()) {
      sl.unregister<GetBillReminderSettingsUseCase>();
    }
  });

  void stub(BillsState state) {
    whenListen(bloc, Stream<BillsState>.value(state), initialState: state);
  }

  // ── Stub `CategoryBloc` (A.2 dari perkakas test bersama) ───────────────────
  void stubCategoriesLoaded({List<CategoryEntity> extra = const []}) {
    final state = CategoryLoaded(categories: [...kategoriBawaan, ...extra]);
    whenListen(
      categoryBloc,
      Stream<CategoryState>.value(state),
      initialState: state,
    );
  }

  /// Harness memakai `buildBillsRoute()` YANG NYATA di dalam
  /// `MaterialApp.router`.
  ///
  /// Sejak form tambah naik jadi halaman (T7), FAB memanggil
  /// `context.push('/bills/new')` — tanpa `GoRouter` di atasnya, tap FAB
  /// melempar. Dan router mini buatan tangan tak cukup: ia akan tetap hijau
  /// walau `buildBillsRoute()` kehilangan rute anaknya. Yang dipasang di sini
  /// adalah tabel rute produksi, jadi merusaknya membuat test ini merah.
  GoRouter buatRouter() =>
      GoRouter(initialLocation: '/bills', routes: [buildBillsRoute()]);

  Widget harness({ThemeData? theme, GoRouter? router}) => MaterialApp.router(
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme,
    routerConfig: router ?? buatRouter(),
  );

  /// Harness `BillItem` TELANJANG (tanpa `BillsBloc`/`GoRouter`) — dipakai
  /// test yang menguji perilaku murni widget itu sendiri (dua target tap
  /// bersarang, hit target ⋮).
  Future<void> pumpItem(
    WidgetTester tester, {
    VoidCallback? onTap,
    VoidCallback? onMenuTap,
  }) => tester.pumpWidget(
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
        body: BillItem(
          bill: buildBill(id: 1, name: 'Kos', dueDate: todayStart),
          todayStart: todayStart,
          onTap: onTap,
          onMenuTap: onMenuTap,
        ),
      ),
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
      lastUndo: snapshotUndo,
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

      verify(() => bloc.add(BillPaymentUndone(snapshotUndo))).called(1);
    });
  });

  // ── Navigasi ke form (T7) ───────────────────────────────────────────────────
  //
  // Sejak form tambah naik jadi halaman penuh, FAB tidak lagi membuka bottom
  // sheet melainkan MENDORONG rute `/bills/new`. Dua test di bawah memakai
  // tabel rute produksi, bukan router tiruan.

  group('navigasi form', () {
    testWidgets('tap FAB "Tambah" mendorong /bills/new dalam mode tambah', (
      tester,
    ) async {
      stub(const BillsState(status: BillsStatus.success));
      final router = buatRouter();
      await tester.pumpWidget(harness(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.billsAdd));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.toString(),
        '/bills/new',
        reason: 'FAB harus mendorong rute, bukan membuka sheet',
      );
      final page = tester.widget<BillFormPage>(find.byType(BillFormPage));
      expect(
        page.bill,
        isNull,
        reason: '/bills/new tak membawa extra — selalu mode tambah',
      );
      expect(find.text(l10n.billsFormAddTitle), findsOneWidget);
    });

    // Menutup celah T6: `same(billEditRedirect)` mengunci REFERENSI callback,
    // bukan isinya — mutasi yang mengubah badan `billEditRedirect` jadi
    // `=> null` lolos di sana. Di sini penjaganya dijalankan sungguhan di
    // dalam GoRouter yang memakai `buildBillsRoute()` nyata.
    testWidgets('deep-link /bills/7/edit tanpa extra mendarat kembali di '
        '/bills — form TIDAK dibangun', (tester) async {
      stub(const BillsState(status: BillsStatus.success));
      final router = buatRouter();
      await tester.pumpWidget(harness(router: router));
      await tester.pumpAndSettle();

      router.push('/bills/7/edit');
      await tester.pumpAndSettle();

      expect(find.byType(BillFormPage), findsNothing);
      expect(router.state.uri.toString(), '/bills');
      expect(tester.takeException(), isNull);
    });

    // Rantai LENGKAP: baris → ⋮ → sheet aksi → Ubah → rute [Audit B4].
    //
    // Diarahkan ulang dari test T13 yang menembak `context.push` SEMENTARA di
    // `_openActionsSheet`. Sejak Task 14, ⋮ tak lagi menavigasi langsung — ia
    // membuka sheet, dan sheet-lah yang mendorong rute. Asersi identitas
    // `same(kos)` dipertahankan: itu yang membuktikan `billEditGuard`
    // menerima instance yang benar, bukan salinan.
    testWidgets('memilih Ubah di sheet mendorong rute ubah dengan bill '
        'sebagai extra', (tester) async {
      final kos = buildBill(id: 42, name: 'Kos Bu Tini', dueDate: todayStart);
      stub(BillsState(status: BillsStatus.success, bills: [kos]));
      stubCategoriesLoaded();
      final router = buatRouter();
      await tester.pumpWidget(harness(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('bill_item_menu_42')));
      await tester.pumpAndSettle();
      // ⋮ HANYA membuka sheet — belum menavigasi ke mana pun.
      expect(
        router.state.uri.toString(),
        '/bills',
        reason: '⋮ membuka sheet dulu, bukan langsung melompat ke form',
      );

      await tester.tap(find.text(l10n.billsActionEdit));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/bills/42/edit');
      final page = tester.widget<BillFormPage>(find.byType(BillFormPage));
      expect(
        page.bill,
        same(kos),
        reason:
            'rute ubah membaca bill dari extra — instance yang SAMA, '
            'bukan salinan, supaya penjaga billEditGuard lolos',
      );
      expect(find.text(l10n.billsFormEditTitle), findsOneWidget);
    });

    testWidgets(
      'menutup sheet aksi tanpa memilih TIDAK menavigasi ke mana pun',
      (tester) async {
        stub(
          BillsState(
            status: BillsStatus.success,
            bills: [
              buildBill(id: 42, name: 'Kos Bu Tini', dueDate: todayStart),
            ],
          ),
        );
        stubCategoriesLoaded();
        final router = buatRouter();
        await tester.pumpWidget(harness(router: router));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('bill_item_menu_42')));
        await tester.pumpAndSettle();
        // Sheet BENAR-BENAR terbuka dulu — tanpa ini, asersi negatif di bawah
        // lulus vakum (tak menavigasi karena tak ada apa-apa yang dibuka).
        expect(find.text(l10n.billsActionEdit), findsOneWidget);

        // Ketuk barrier di luar sheet.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text(l10n.billsActionEdit), findsNothing);
        expect(router.state.uri.toString(), '/bills');
        verifyNever(() => bloc.add(any(that: isA<BillDeleted>())));
      },
    );
  });

  // ── Dialog konfirmasi hapus (Task 14) ───────────────────────────────────────
  //
  // Dialog dibuka lewat JALUR NYATA: baris → ⋮ → sheet → Hapus. Sengaja tidak
  // memanggil dialognya langsung — yang diuji rantainya, bukan dialognya
  // sendirian.
  group('dialog hapus', () {
    Future<void> bukaDialogHapus(
      WidgetTester tester, {
      required int installmentsPaid,
      int id = 1,
      String name = 'Kos Bu Tini',
      ThemeData? theme,
    }) async {
      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [
            buildBill(
              id: id,
              name: name,
              dueDate: todayStart,
              installmentsPaid: installmentsPaid,
              installmentTotal: installmentsPaid > 0 ? 12 : null,
            ),
          ],
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness(theme: theme));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('bill_item_menu_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.billsActionDelete));
      await tester.pumpAndSettle();
    }

    testWidgets('tagihan TANPA riwayat: kalimat pendek, tanpa janji kosong', (
      tester,
    ) async {
      await bukaDialogHapus(tester, installmentsPaid: 0);

      expect(find.text(l10n.billsDeleteBodyClean), findsOneWidget);
      expect(find.text(l10n.billsDeleteBodyPaid), findsNothing);
    });

    testWidgets('tagihan BERRIWAYAT: menyebut Transaksi', (tester) async {
      await bukaDialogHapus(tester, installmentsPaid: 3);

      expect(find.text(l10n.billsDeleteBodyPaid), findsOneWidget);
      expect(find.text(l10n.billsDeleteBodyClean), findsNothing);
    });

    testWidgets('judul dialog menyebut nama tagihan', (tester) async {
      await bukaDialogHapus(tester, installmentsPaid: 0, name: 'Wifi Indihome');

      expect(find.text(l10n.billsDeleteTitle('Wifi Indihome')), findsOneWidget);
    });

    testWidgets('konfirmasi mengirim BillDeleted dengan id yang benar', (
      tester,
    ) async {
      await bukaDialogHapus(tester, installmentsPaid: 0, id: 42);

      await tester.tap(find.text(l10n.billsDeleteConfirm));
      await tester.pumpAndSettle();

      verify(() => bloc.add(const BillDeleted(42))).called(1);
    });

    testWidgets('batal TIDAK mengirim BillDeleted', (tester) async {
      await bukaDialogHapus(tester, installmentsPaid: 0, id: 42);

      await tester.tap(find.text(l10n.btnCancel));
      await tester.pumpAndSettle();

      verifyNever(() => bloc.add(any(that: isA<BillDeleted>())));
    });

    // Membuktikan asersi negatif di test "batal" TIDAK lulus vakum: dari
    // keadaan yang sama, jalur konfirmasi memang menghasilkan BillDeleted.
    testWidgets('menutup dialog dengan barrier juga TIDAK menghapus', (
      tester,
    ) async {
      await bukaDialogHapus(tester, installmentsPaid: 0, id: 42);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text(l10n.billsDeleteConfirm), findsNothing);
      verifyNever(() => bloc.add(any(that: isA<BillDeleted>())));
    });

    testWidgets('tombol dialog memenuhi hit target 48dp', (tester) async {
      await bukaDialogHapus(tester, installmentsPaid: 0);

      for (final label in [l10n.btnCancel, l10n.billsDeleteConfirm]) {
        expect(
          tester.getSize(find.widgetWithText(TextButton, label)).height,
          greaterThanOrEqualTo(48),
          reason: 'tombol "$label" di bawah hit target minimum',
        );
      }
    });

    testWidgets('aksi Hapus di dialog memakai AppColors.warn', (tester) async {
      await bukaDialogHapus(tester, installmentsPaid: 0);

      final teks = tester.widget<Text>(
        find.descendant(
          of: find.widgetWithText(TextButton, l10n.billsDeleteConfirm),
          matching: find.byType(Text),
        ),
      );
      expect(teks.style?.color, AppColors.warn);
    });

    testWidgets('dark mode: dialog render tanpa error dan pakai cardDark', (
      tester,
    ) async {
      await bukaDialogHapus(
        tester,
        installmentsPaid: 0,
        theme: ThemeData.dark(),
      );

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.backgroundColor, AppColors.cardDark);
      expect(tester.takeException(), isNull);
    });
  });

  // ── Ikon kategori + pintu aksi ⋮ (Task 13) ──────────────────────────────────
  group('ikon kategori + pintu aksi ⋮', () {
    testWidgets('baris memakai ikon KATEGORI, bukan ikon tagihan seragam', (
      tester,
    ) async {
      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [buildBill(id: 1, name: 'Kos', dueDate: todayStart)],
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);
    });

    testWidgets('kategori kustom memakai ikon dari iconSlug', (tester) async {
      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [
            buildBill(
              id: 1,
              name: 'Kursus',
              dueDate: todayStart,
            ).copyWith(category: 'kursus_bahasa'),
          ],
        ),
      );
      stubCategoriesLoaded(
        extra: [katKustom(slug: 'kursus_bahasa', iconSlug: 'school')],
      );
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('CategoryBloc belum siap → ikon tagihan lama sebagai antara, '
        'bukan ikon grid generik', (tester) async {
      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [buildBill(id: 1, name: 'Kos', dueDate: todayStart)],
        ),
      );
      whenListen(
        categoryBloc,
        Stream<CategoryState>.value(const CategoryLoading()),
        initialState: const CategoryLoading(),
      );
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('ikon ⋮ tampil di tiap baris', (tester) async {
      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [
            buildBill(id: 1, name: 'Kos', dueDate: todayStart),
            buildBill(id: 2, name: 'Wifi', dueDate: todayStart),
          ],
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('bill_item_menu_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('bill_item_menu_2')), findsOneWidget);
    });

    testWidgets('menekan ⋮ TIDAK ikut memicu onTap baris', (tester) async {
      var barisDitekan = 0;
      var menuDitekan = 0;
      await pumpItem(
        tester,
        onTap: () => barisDitekan++,
        onMenuTap: () => menuDitekan++,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('bill_item_menu_1')));
      await tester.pumpAndSettle();

      expect(menuDitekan, 1);
      expect(barisDitekan, 0, reason: 'ketukan tak boleh menembus ke baris');
    });

    testWidgets('⋮ memenuhi hit target 48dp', (tester) async {
      await pumpItem(tester, onMenuTap: () {});
      await tester.pumpAndSettle();

      final size = tester.getSize(
        find.byKey(const ValueKey('bill_item_menu_1')),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('onMenuTap null → ⋮ tidak digambar', (tester) async {
      await pumpItem(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('bill_item_menu_1')), findsNothing);
    });

    // Menggantikan sabotase "InkResponse → GestureDetector" (mustahil merah —
    // recognizer terdalam selalu menang arena gestur). Test ini menjaga hal
    // yang jauh lebih penting: tagihan yang tak bisa ditandai lunas lagi
    // TETAP punya pintu ubah/hapus. Menyamakan `onMenuTap` dengan
    // `canMarkPaid` menghidupkan kembali persis bug yang gelombang ini ada
    // untuk memperbaikinya.
    testWidgets('tagihan yang cicilannya TAMAT tetap punya ⋮', (tester) async {
      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [
            buildBill(
              id: 1,
              name: 'Cicilan HP',
              dueDate: todayStart,
              status: BillStatus.completed,
              installmentTotal: 12,
              installmentsPaid: 12,
            ),
          ],
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('bill_item_menu_1')),
        findsOneWidget,
        reason: 'tak bisa ditandai lunas ≠ tak bisa diubah atau dihapus',
      );
    });

    testWidgets(
      'baris berikut tetap muat di layar 320dp dengan nominal delapan digit '
      '[Audit S8]',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        stub(
          BillsState(
            status: BillsStatus.success,
            bills: [
              buildBill(
                id: 1,
                name: 'Cicilan motor Honda Beat',
                dueDate: todayStart,
                estimatedAmount: 12450000,
              ),
            ],
          ),
        );
        stubCategoriesLoaded();
        await tester.pumpWidget(harness());
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'RenderFlex overflow di baris daftar = pita kuning-hitam',
        );
      },
    );

    // ── Fix round 1 (review Important-1) ────────────────────────────────────
    //
    // "Tidak melempar exception" saja tak cukup — dua anak fleksibel yang
    // TIDAK sama-sama tight bisa lolos dari overflow tapi tetap memotong
    // nominal di lebar NORMAL dan membuat kolom ⋮ ragged (tak rata kanan).
    // Dua test di bawah mengunci sifat itu secara eksplisit, terpisah dari
    // sekadar "tak melempar".
    testWidgets('kolom ⋮ rata kanan berapa pun panjang nominal — tak ragged '
        '[review S8]', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [
            // Nominal bill 1 SENGAJA sangat pendek ("Rp 100") — dua nilai
            // yang sama-sama panjang bisa kebetulan sama-sama terpotong ke
            // lebar jatah yang identik di bawah struktur kompetisi-flex yang
            // salah, membuat dx tetap sama walau ⋮ sebenarnya ragged. Pasangan
            // pendek-vs-panjang ini yang benar-benar membedah bug-nya.
            buildBill(
              id: 1,
              name: 'Kos',
              dueDate: todayStart,
              estimatedAmount: 100,
            ),
            buildBill(
              id: 2,
              name: 'Cicilan motor Honda Beat',
              dueDate: todayStart,
              estimatedAmount: 12450000,
            ),
          ],
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final dx1 = tester
          .getTopRight(find.byKey(const ValueKey('bill_item_menu_1')))
          .dx;
      final dx2 = tester
          .getTopRight(find.byKey(const ValueKey('bill_item_menu_2')))
          .dx;
      expect(
        dx1,
        dx2,
        reason:
            'kolom ⋮ harus rata kanan yang sama persis di kedua baris, '
            'terlepas dari panjang nominal',
      );
    });

    testWidgets('nominal delapan digit TIDAK terpotong di lebar normal (360dp) '
        '[review S8]', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [
            buildBill(
              id: 1,
              name: 'Cicilan motor Honda Beat',
              dueDate: todayStart,
              estimatedAmount: 12450000,
            ),
          ],
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(formatRupiah(12450000)),
      );
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason:
            'nominal 8 digit tak boleh terpotong di lebar 360dp — hanya '
            'jaring pengaman untuk skenario benar-benar ekstrem',
      );
    });

    testWidgets('⋮ punya node semantik sendiri: label "Aksi tagihan", aksi tap '
        '[review Important-3]', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpItem(tester, onMenuTap: () {});
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byKey(const ValueKey('bill_item_menu_1'))),
        matchesSemantics(
          label: l10n.billsActionsMenuA11y,
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });
  });

  // ── Kanal galat tulis di daftar (§2.6, Task 5) ──────────────────────────────
  //
  // Daftar tidak menutup apa pun sesudah aksi ini — ia BERBICARA untuk dua
  // aksi yang tak punya permukaan lain di atasnya: `delete` dan
  // `undoPayment`. Kalau daftar diam, kedua kegagalan itu tak terlihat sama
  // sekali oleh pengguna.
  group('kanal galat tulis di daftar (§2.6)', () {
    BillsState gagalTulis(BillWriteAction aksi, {int? billId, int seq = 1}) =>
        BillsState(
          status: BillsStatus.success,
          bills: [buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart)],
          actionFailure: BillActionFailure(
            aksi: aksi,
            failure: const CacheFailure('db mati'),
            seq: seq,
            billId: billId,
          ),
        );

    testWidgets('gagal hapus → snackbar tampil, daftar TETAP tergambar', (
      tester,
    ) async {
      whenListen(
        bloc,
        Stream<BillsState>.value(gagalTulis(BillWriteAction.delete, billId: 7)),
        initialState: BillsState(
          status: BillsStatus.success,
          bills: [buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart)],
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.billsDeleteFailed), findsOneWidget);
      expect(find.byType(BillItem), findsOneWidget);
      expect(find.text(l10n.billsError), findsNothing);
    });

    testWidgets('gagal hapus → "Coba lagi" mengirim ulang BillDeleted', (
      tester,
    ) async {
      // [Review Important-1] `billId` di `actionFailure` SENGAJA beda dari id
      // bill PERTAMA di daftar, dan daftarnya berisi DUA bill — bukan satu.
      // Sebelum perbaikan ini, `bills` cuma berisi id 7 dan `billId` galat
      // JUGA 7, jadi implementasi yang keliru membaca `state.bills.first.id`
      // (alih-alih `gagal.billId`) lolos memberi `BillDeleted(7)` — angka
      // yang sama persis dengan yang benar. Dengan id 42 bukan elemen
      // pertama, implementasi yang salah sumber mengirim `BillDeleted(7)`
      // dan test ini MERAH, bukan kebetulan hijau.
      final bills = [
        buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart),
        buildBill(id: 42, name: 'Kos Bu Tini', dueDate: todayStart),
      ];
      whenListen(
        bloc,
        Stream<BillsState>.value(
          BillsState(
            status: BillsStatus.success,
            bills: bills,
            actionFailure: const BillActionFailure(
              aksi: BillWriteAction.delete,
              failure: CacheFailure('db mati'),
              seq: 1,
              billId: 42,
            ),
          ),
        ),
        initialState: BillsState(status: BillsStatus.success, bills: bills),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.pump();
      // Selama animasi masuk, snackbar masih dibungkus IgnorePointer — tap-nya
      // meleset kalau tidak ditunggu sampai diam (preseden: test "tap
      // Urungkan" di grup 'snackbar undo').
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.text(l10n.retry));
      await tester.pump();

      verify(() => bloc.add(const BillDeleted(42))).called(1);
    });

    testWidgets('gagal undo → "Coba lagi" mengirim ulang BillPaymentUndone', (
      tester,
    ) async {
      // Spec §2.9 #14. Tanpa test ini, aksi retry pada cabang undo terpasang
      // tanpa pengunci — mencabutnya tak membuat satu pun test memerah,
      // padahal ia satu-satunya jalan pulih yang dipunyai pengguna.
      final gagal = gagalTulis(BillWriteAction.undoPayment, billId: 7);
      whenListen(
        bloc,
        Stream<BillsState>.value(gagal.copyWith(lastUndo: snapshotUndo)),
        initialState: BillsState(
          status: BillsStatus.success,
          bills: [buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart)],
          lastUndo: snapshotUndo,
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.pump();
      // Selama animasi masuk, snackbar masih dibungkus IgnorePointer — tap-nya
      // meleset kalau tidak ditunggu sampai diam (preseden: test "tap
      // Urungkan" di grup 'snackbar undo').
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.text(l10n.retry));
      await tester.pump();

      verify(() => bloc.add(BillPaymentUndone(snapshotUndo))).called(1);
    });

    testWidgets('gagal undo → snackbar tampil (tidak senyap)', (tester) async {
      whenListen(
        bloc,
        Stream<BillsState>.value(
          gagalTulis(BillWriteAction.undoPayment, billId: 7),
        ),
        initialState: BillsState(
          status: BillsStatus.success,
          bills: [buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart)],
        ),
      );
      stubCategoriesLoaded();
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.billsUndoFailed), findsOneWidget);
    });

    testWidgets(
      'snackbar gagal-tulis menggusur snackbar undo, lastUndo tetap',
      (tester) async {
        final undo = BillsState(
          status: BillsStatus.success,
          bills: [buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart)],
          lastUndo: snapshotUndo,
        );
        whenListen(
          bloc,
          Stream<BillsState>.fromIterable([
            undo,
            undo.copyWith(
              actionFailure: const BillActionFailure(
                aksi: BillWriteAction.delete,
                failure: CacheFailure('db mati'),
                seq: 1,
                billId: 7,
              ),
            ),
          ]),
          initialState: const BillsState(status: BillsStatus.success),
        );
        stubCategoriesLoaded();
        await tester.pumpWidget(harness());
        await tester.pump();
        await tester.pump();
        // BUKAN `pump()` berdurasi nol. `hideCurrentSnackBar()` menjalankan
        // animasi keluar, dan `showSnackBar` berikutnya MENGANTRE sampai yang
        // lama benar-benar lepas dari pohon. Dengan pompaan nol, snackbar galat
        // belum masuk DAN snackbar undo belum keluar — kedua asersi di bawah
        // gagal karena waktu, bukan karena kode.
        await tester.pump(const Duration(milliseconds: 750));

        expect(find.text(l10n.billsDeleteFailed), findsOneWidget);
        expect(find.text(l10n.billsUndo), findsNothing);
      },
    );
  });

  group('pemulihan ikon kategori (§4)', () {
    testWidgets(
      'CategoryError → satu percobaan ulang otomatis sesudah 2 detik',
      (tester) async {
        stub(
          BillsState(
            status: BillsStatus.success,
            bills: [
              buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart),
            ],
          ),
        );
        whenListen(
          categoryBloc,
          Stream<CategoryState>.value(const CategoryError('db mati')),
          initialState: const CategoryError('db mati'),
        );
        await tester.pumpWidget(harness());
        await tester.pump();

        clearInteractions(categoryBloc);
        await tester.pump(const Duration(seconds: 2));

        verify(() => categoryBloc.add(const LoadCategories())).called(1);
      },
    );

    testWidgets('masih gagal sesudah percobaan → TIDAK mencoba lagi', (
      tester,
    ) async {
      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart)],
        ),
      );
      // `StreamController`, BUKAN `Stream.value` — stream sekali-pancar
      // hanya bisa mengirim SATU `CategoryError`, jadi ada-tidaknya penjaga
      // tak pernah kelihatan bedanya (add() paling banyak sekali terjadi
      // apa pun keadaan penjaganya). Episode galat yang SAMA di sini
      // dikirim DUA kali lewat stream, mensimulasikan galat yang menetap —
      // baru di situ penjaga (atau ketiadaannya) benar-benar diuji.
      final ctrl = StreamController<CategoryState>.broadcast();
      addTearDown(ctrl.close);
      whenListen(
        categoryBloc,
        ctrl.stream,
        initialState: const CategoryError('db mati'),
      );
      await tester.pumpWidget(harness());
      await tester.pump();
      ctrl.add(const CategoryError('db mati'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      clearInteractions(categoryBloc);
      ctrl.add(const CategoryError('db mati'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      verifyNever(() => categoryBloc.add(const LoadCategories()));
    });

    testWidgets('gagal → percobaan → berhasil: ikon kategori tergambar', (
      tester,
    ) async {
      stub(
        BillsState(
          status: BillsStatus.success,
          bills: [
            buildBill(
              id: 7,
              name: 'Wifi Indihome',
              dueDate: todayStart,
            ).copyWith(category: 'internet'),
          ],
        ),
      );
      final ctrl = StreamController<CategoryState>.broadcast();
      addTearDown(ctrl.close);
      whenListen(
        categoryBloc,
        ctrl.stream,
        initialState: const CategoryError('db mati'),
      );
      // KUNCINYA ADA DI SINI. `CategoryLoaded` LAHIR DARI `add`-nya, bukan
      // didorong tangan oleh test. Kalau ia didorong tangan, test ini tetap
      // hijau walau SELURUH implementasi task ini dicabut — pemulihan yang
      // "terbukti" tanpa pernah dipicu apa pun.
      when(
        () => categoryBloc.add(const LoadCategories()),
      ).thenAnswer((_) => ctrl.add(CategoryLoaded(categories: kategoriBawaan)));
      await tester.pumpWidget(harness());
      await tester.pump();
      // `BlocListener` hanya bereaksi pada EVENT lewat stream — `initialState`
      // di `whenListen` cuma menyetel `bloc.state` untuk `BlocBuilder`, TIDAK
      // pernah lewat stream (lihat `bloc_test`'s `when_listen.dart`). Tanpa
      // baris ini galat "sudah menetap sejak awal" tak pernah dilihat
      // listener retry, beda dari situasi nyata: `CategoryBloc` di
      // `app_router.dart` mengirim `LoadCategories()` lalu `BillsListPage`
      // subscribe SEBELUM bloc sempat emit `CategoryError`-nya sendiri lewat
      // stream — persis yang disimulasikan baris ini.
      ctrl.add(const CategoryError('db mati'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);
    });

    testWidgets(
      'halaman ditutup sebelum timer → tak ada add & tak ada exception',
      (tester) async {
        stub(
          BillsState(
            status: BillsStatus.success,
            bills: [
              buildBill(id: 7, name: 'Wifi Indihome', dueDate: todayStart),
            ],
          ),
        );
        whenListen(
          categoryBloc,
          Stream<CategoryState>.value(const CategoryError('db mati')),
          initialState: const CategoryError('db mati'),
        );
        await tester.pumpWidget(harness());
        await tester.pump();

        clearInteractions(categoryBloc);
        await tester.pumpWidget(const SizedBox.shrink());
        // SENGAJA kurang dari `_jedaMuatUlangKategori` (2 detik) — kalau
        // dipompa LEBIH lama dari jeda, timer keburu meluncur wajar sebelum
        // test berakhir dan lolos jadi "timer tertinggal" apa pun nasib
        // `cancel()`-nya di `dispose()`. Dengan 1 detik, timer masih AKTIF
        // saat test berakhir — kalau `dispose()` tak membatalkannya,
        // harness Flutter melempar "A Timer is still pending even after
        // the widget tree was disposed" di titik ini.
        await tester.pump(const Duration(seconds: 1));

        verifyNever(() => categoryBloc.add(const LoadCategories()));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
