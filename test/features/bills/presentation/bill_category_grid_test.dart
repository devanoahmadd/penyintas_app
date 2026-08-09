import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/bill_category_grid.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';

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
  });

  CategoryEntity kat({
    required int id,
    required String slug,
    String? labelKey,
    String? labelOverride,
    String type = 'expense',
    int sortOrder = 10,
    String? iconSlug,
    bool isBuiltIn = true,
  }) => CategoryEntity(
    id: id,
    slug: slug,
    labelKey: labelKey,
    labelOverride: labelOverride,
    isBuiltIn: isBuiltIn,
    isLimitable: true,
    type: type,
    sortOrder: sortOrder,
    iconSlug: iconSlug,
  );

  // SENGAJA tanpa `other`: ikon kategori `other` adalah
  // `Icons.grid_view_outlined`, ikon yang sama dengan tile yatim, sehingga
  // asersi `findsNothing` untuk ikon itu jadi tak bermakna.
  final bawaan = [
    kat(id: 1, slug: 'food', labelKey: 'category_food', sortOrder: 10),
    kat(
      id: 2,
      slug: 'transport',
      labelKey: 'category_transport',
      sortOrder: 20,
    ),
    kat(id: 3, slug: 'fixed', labelKey: 'category_fixed', sortOrder: 30),
    kat(
      id: 9,
      slug: 'income',
      labelKey: 'category_income',
      type: 'income',
      sortOrder: 90,
    ),
  ];

  Widget harness({
    required List<CategoryEntity> categories,
    String? selected,
    void Function(String)? onSelected,
    ThemeData? theme,
  }) => MaterialApp(
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
      body: SingleChildScrollView(
        child: BillCategoryGrid(
          categories: categories,
          selectedSlug: selected,
          onSelected: onSelected ?? (_) {},
        ),
      ),
    ),
  );

  // ── I6: income tak pernah bisa dipilih ──────────────────────────────────

  testWidgets('kategori income TIDAK digambar', (tester) async {
    await tester.pumpWidget(harness(categories: bawaan));
    await tester.pumpAndSettle();
    expect(find.text(l10n.categoryIncome), findsNothing);
    expect(find.text(l10n.categoryFood), findsOneWidget);
  });

  testWidgets('slug income tak pernah bisa dikirim lewat onSelected', (
    tester,
  ) async {
    final terpilih = <String>[];
    await tester.pumpWidget(
      harness(categories: bawaan, onSelected: terpilih.add),
    );
    await tester.pumpAndSettle();
    for (final t in find.byType(InkWell).evaluate().toList()) {
      await tester.tap(find.byWidget(t.widget as InkWell));
      await tester.pump();
    }
    expect(terpilih, isNot(contains('income')));
  });

  // ── Layout ──────────────────────────────────────────────────────────────

  testWidgets('grid memakai 3 kolom', (tester) async {
    await tester.pumpWidget(harness(categories: bawaan));
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
  });

  testWidgets('grid tak menggulir sendiri — halaman yang menggulir', (
    tester,
  ) async {
    await tester.pumpWidget(harness(categories: bawaan));
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.shrinkWrap, isTrue);
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
  });

  testWidgets('urutan mengikuti sortOrder, bukan urutan masukan', (
    tester,
  ) async {
    final acak = [
      kat(id: 3, slug: 'fixed', labelKey: 'category_fixed', sortOrder: 30),
      kat(id: 1, slug: 'food', labelKey: 'category_food', sortOrder: 10),
      kat(
        id: 2,
        slug: 'transport',
        labelKey: 'category_transport',
        sortOrder: 20,
      ),
    ];
    await tester.pumpWidget(harness(categories: acak));
    await tester.pumpAndSettle();
    final xFood = tester.getTopLeft(find.text(l10n.categoryFood)).dx;
    final xTransport = tester.getTopLeft(find.text(l10n.categoryTransport)).dx;
    expect(xFood, lessThan(xTransport));
  });

  // ── Label & ikon kategori kustom ────────────────────────────────────────

  testWidgets('kategori kustom memakai labelOverride, BUKAN slug mentah', (
    tester,
  ) async {
    final kustom = [
      kat(
        id: 50,
        slug: 'kursus_bahasa',
        labelOverride: 'Kursus Bahasa Inggris',
        iconSlug: 'school',
        isBuiltIn: false,
        sortOrder: 100,
      ),
    ];
    await tester.pumpWidget(harness(categories: kustom));
    await tester.pumpAndSettle();
    expect(find.text('Kursus Bahasa Inggris'), findsOneWidget);
    expect(find.text('kursus_bahasa'), findsNothing);
  });

  testWidgets(
    'kategori kustom memakai ikon dari iconSlug, bukan ikon generik',
    (tester) async {
      final kustom = [
        kat(
          id: 50,
          slug: 'kursus_bahasa',
          labelOverride: 'Kursus',
          iconSlug: 'school',
          isBuiltIn: false,
          sortOrder: 100,
        ),
      ];
      await tester.pumpWidget(harness(categories: kustom));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_outlined), findsNothing);
    },
  );

  // ── Kategori yatim (D9) ─────────────────────────────────────────────────

  testWidgets(
    'slug terpilih yang hilang dari daftar dapat tile yatim berlabel rapi',
    (tester) async {
      await tester.pumpWidget(
        harness(categories: bawaan, selected: 'kursus_bahasa'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kursus bahasa'), findsOneWidget);
    },
  );

  testWidgets('tile yatim ada di URUTAN TERAKHIR', (tester) async {
    await tester.pumpWidget(
      harness(categories: bawaan, selected: 'kursus_bahasa'),
    );
    await tester.pumpAndSettle();
    final yYatim = tester.getTopLeft(find.text('Kursus bahasa')).dy;
    final yFixed = tester.getTopLeft(find.text(l10n.categoryFixed)).dy;
    expect(yYatim, greaterThanOrEqualTo(yFixed));
  });

  testWidgets('tile yatim memakai ikon grid generik', (tester) async {
    await tester.pumpWidget(
      harness(categories: bawaan, selected: 'kursus_bahasa'),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.grid_view_outlined), findsWidgets);
  });

  testWidgets(
    'daftar KOSONG tidak menghasilkan tile yatim — kosong bukan berarti '
    'terhapus',
    (tester) async {
      await tester.pumpWidget(
        harness(categories: const [], selected: 'kursus_bahasa'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kursus bahasa'), findsNothing);
    },
  );

  testWidgets(
    'slug terpilih yang ADA di daftar tidak menghasilkan tile yatim',
    (tester) async {
      await tester.pumpWidget(harness(categories: bawaan, selected: 'food'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.categoryFood), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_outlined), findsNothing);
    },
  );

  testWidgets('tile yatim BISA ditekan dan mengirim slug aslinya', (
    tester,
  ) async {
    final terpilih = <String>[];
    await tester.pumpWidget(
      harness(
        categories: bawaan,
        selected: 'kursus_bahasa',
        onSelected: terpilih.add,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kursus bahasa'));
    await tester.pump();
    expect(terpilih, ['kursus_bahasa']);
  });

  // ── Urutan khusus layar ini [Audit T3] ──────────────────────────────────

  testWidgets(
    'kategori "fixed" berdiri di tile PERTAMA, mendahului sortOrder DB',
    (tester) async {
      // sortOrder seperti PRODUKSI: fixed justru paling belakang.
      final sepertiProduksi = [
        kat(id: 1, slug: 'food', labelKey: 'category_food', sortOrder: 0),
        kat(
          id: 2,
          slug: 'transport',
          labelKey: 'category_transport',
          sortOrder: 1,
        ),
        kat(id: 7, slug: 'other', labelKey: 'category_other', sortOrder: 5),
        kat(id: 3, slug: 'fixed', labelKey: 'category_fixed', sortOrder: 6),
      ];
      await tester.pumpWidget(harness(categories: sepertiProduksi));
      await tester.pumpAndSettle();

      final pFixed = tester.getTopLeft(find.text(l10n.categoryFixed));
      final pFood = tester.getTopLeft(find.text(l10n.categoryFood));
      expect(pFixed.dy, lessThanOrEqualTo(pFood.dy));
      expect(
        pFixed.dx,
        lessThan(pFood.dx),
        reason:
            'kos/cicilan adalah kategori tagihan yang paling sering dipakai — '
            'ia tak boleh turun ke baris ketiga',
      );
    },
  );

  testWidgets('sisanya tetap urut sortOrder di belakang "fixed"', (
    tester,
  ) async {
    final sepertiProduksi = [
      kat(id: 7, slug: 'other', labelKey: 'category_other', sortOrder: 5),
      kat(id: 3, slug: 'fixed', labelKey: 'category_fixed', sortOrder: 6),
      kat(id: 1, slug: 'food', labelKey: 'category_food', sortOrder: 0),
    ];
    await tester.pumpWidget(harness(categories: sepertiProduksi));
    await tester.pumpAndSettle();
    final xFood = tester.getTopLeft(find.text(l10n.categoryFood)).dx;
    final xOther = tester.getTopLeft(find.text(l10n.categoryOther)).dx;
    expect(xFood, lessThan(xOther), reason: 'food(0) sebelum other(5)');
  });

  // ── Hit target ──────────────────────────────────────────────────────────

  testWidgets('tiap tile setinggi minimal 64dp', (tester) async {
    await tester.pumpWidget(harness(categories: bawaan));
    await tester.pumpAndSettle();
    final tinggi = tester.getSize(find.byType(InkWell).first).height;
    expect(tinggi, greaterThanOrEqualTo(64));
  });

  testWidgets('tile TIDAK menjulang mengikuti lebar layar [Audit S9]', (
    tester,
  ) async {
    // Viewport lebar — dengan childAspectRatio: 1.0 tile jadi ratusan dp.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(categories: bawaan));
    await tester.pumpAndSettle();
    final tinggi = tester.getSize(find.byType(InkWell).first).height;
    expect(
      tinggi,
      lessThanOrEqualTo(96),
      reason: 'tinggi tile harus tetap, bukan turunan dari lebar',
    );
  });

  // ── Keadaan terpilih dibedakan TANPA bergantung warna [gerbang UX] ───────
  //
  // `color-not-only` (severity HIGH): satu-satunya pembeda tak boleh warna.
  // Tile terpilih di sini berbeda dalam TIGA hal sekaligus — isi permukaan,
  // bobot huruf, dan bendera semantik — sehingga tetap terbaca oleh pengguna
  // yang tak membedakan hue maupun oleh pembaca layar.

  testWidgets('tile terpilih ditandai bendera semantik, bukan cuma warna', (
    tester,
  ) async {
    await tester.pumpWidget(harness(categories: bawaan, selected: 'food'));
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text(l10n.categoryFood)),
      matchesSemantics(
        // Label muncul SEKALI: tile tak boleh menyalin teksnya sendiri ke
        // `Semantics.label` — pembaca layar akan mengucapkannya dua kali.
        label: l10n.categoryFood,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text(l10n.categoryTransport)),
      matchesSemantics(
        label: l10n.categoryTransport,
        isButton: true,
        hasSelectedState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('tile terpilih memakai bobot huruf lebih tebal', (tester) async {
    await tester.pumpWidget(harness(categories: bawaan, selected: 'food'));
    await tester.pumpAndSettle();

    FontWeight? bobot(String label) =>
        tester.widget<Text>(find.text(label)).style?.fontWeight;

    expect(bobot(l10n.categoryFood), FontWeight.w700);
    expect(
      bobot(l10n.categoryTransport),
      isNot(FontWeight.w700),
      reason: 'tanpa beda bobot, satu-satunya pembeda tinggal warna',
    );
  });

  // ── Dark mode ───────────────────────────────────────────────────────────

  testWidgets('dark mode render tanpa error', (tester) async {
    await tester.pumpWidget(
      harness(categories: bawaan, selected: 'fixed', theme: ThemeData.dark()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.categoryFixed), findsOneWidget);
  });
}
