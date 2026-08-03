import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_bill_commitments.dart';
import 'package:penyintas_app/features/bills/presentation/widgets/tied_money_row.dart';

/// Task 7.2c — baris "uang terikat / sisa aman" di dalam kartu saldo.
///
/// Inti P1 "pivot flag": tagihan ber-`isFixedNeed` sudah dipotong di muka
/// lewat `fixedExpenses`, jadi hanya BOLEH ditampilkan; tagihan bebas
/// benar-benar mengurangi sisa saldo. Test di sini mengunci agar pemisahan
/// itu terlihat oleh pengguna — dan agar toggle privasi saldo tidak bocor
/// lewat baris baru ini.
///
/// Harness l10n sinkron mengikuti `mark_bill_paid_sheet_test.dart`; harness
/// navigasi `GoRouter` mengikuti `dashboard_bills_tile_test.dart`.
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

  // ── Fixture varian (spec §6) ────────────────────────────────────────────
  // A: semua tagihan sudah dianggarkan (tiedFlexible == 0) → baris kesadaran.
  const varianA = BillCommitments(
    tiedTotal: 500000,
    tiedFlexible: 0,
    safeRemaining: 2200000,
  );
  // B: campuran — sebagian terikat & mengurangi saldo, sebagian dianggarkan.
  const varianB = BillCommitments(
    tiedTotal: 700000,
    tiedFlexible: 200000,
    safeRemaining: 2000000,
  );
  // B tanpa porsi fixed — segmen "sudah dianggarkan" tak punya isi.
  const varianBTanpaFixed = BillCommitments(
    tiedTotal: 200000,
    tiedFlexible: 200000,
    safeRemaining: 2000000,
  );
  // C "normal": sisa aman negatif TAPI saldo kartu belum ter-clamp.
  // Saldo pra-clamp = safeRemaining + tiedFlexible = −400.000 + 900.000
  // = 500.000 ≥ 0 → kartu merender Rp 500.000, jadi 500.000 − 900.000 =
  // −400.000 masih bisa dibaca ulang. Nominal turunan sah tampil.
  const varianC = BillCommitments(
    tiedTotal: 900000,
    tiedFlexible: 900000,
    safeRemaining: -400000,
  );
  // C "ter-clamp": saldo pra-clamp = −400.000 + 100.000 = −300.000 < 0 →
  // kartu merender `totalRemaining` yang sudah di-clamp jadi Rp 0. Di layar
  // 0 − 100.000 ≠ −400.000, jadi baris ini WAJIB berhenti mengklaim turunan.
  const varianCTerClamp = BillCommitments(
    tiedTotal: 300000,
    tiedFlexible: 100000,
    safeRemaining: -400000,
  );
  // Nudge §6.2 — tagihan tetap > kebutuhan tetap yang dianggarkan.
  const nudgeOn = BillCommitments(
    tiedTotal: 700000,
    tiedFlexible: 0,
    safeRemaining: 2200000,
    nudgeBudgetMismatch: true,
  );

  const mainKey = ValueKey('tied_money_row_main');
  const nudgeKey = ValueKey('tied_nudge');
  const negativeIconKey = ValueKey('tied_negative_icon');

  // Router tiga-rute minimal: '/' merender baris, dua rute tujuan hanya
  // memasang penanda supaya navigasi terverifikasi tanpa menyeret halaman
  // sungguhan beserta bloc-nya.
  GoRouter buildTestRouter(
    BillCommitments commitments, {
    bool hidden = false,
  }) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TiedMoneyRow(commitments: commitments, hidden: hidden),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/bills',
        builder: (context, state) =>
            const Scaffold(body: Text('BILLS_PAGE_MARKER')),
      ),
      GoRoute(
        path: '/budget/edit-settings',
        builder: (context, state) =>
            const Scaffold(body: Text('BUDGET_SETTINGS_MARKER')),
      ),
    ],
  );

  Widget harness(
    BillCommitments commitments, {
    bool hidden = false,
    ThemeData? theme,
  }) => MaterialApp.router(
    routerConfig: buildTestRouter(commitments, hidden: hidden),
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

  /// Harness tanpa router — untuk test yang perlu MENGUBAH prop antar frame
  /// (toggle privasi) atau mengutak-atik `MediaQuery`. Callback navigasi
  /// `TiedMoneyRow` baru dievaluasi saat ditap, jadi `GoRouter` tak perlu.
  Widget plainHarness(
    Widget child, {
    double width = 360,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: Scaffold(
          body: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [child],
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('aturan sembunyi #1: tiedTotal==0 → tidak dirender', (
    tester,
  ) async {
    await tester.pumpWidget(harness(BillCommitments.empty));
    await tester.pumpAndSettle();

    // Widget tetap ada di tree (dipasang tanpa syarat oleh kartu saldo),
    // tapi TIDAK boleh memakan ruang sedikit pun.
    expect(find.byType(TiedMoneyRow), findsOneWidget);
    expect(tester.getSize(find.byType(TiedMoneyRow)), Size.zero);
    expect(find.text(l10n.dashboardTiedEyebrow), findsNothing);
    expect(find.text(l10n.dashboardTiedEyebrowInfo), findsNothing);
  });

  testWidgets(
    'varian A: eyebrow info + nominal + suffix, TANPA "Aman dipakai"',
    (tester) async {
      await tester.pumpWidget(harness(varianA));
      await tester.pumpAndSettle();

      expect(find.text('Tagihan sebelum gajian'), findsOneWidget);
      expect(find.textContaining('Rp 500.000'), findsOneWidget);
      expect(
        find.textContaining('sudah dianggarkan dari kebutuhan tetapmu'),
        findsOneWidget,
      );

      // Inti pivot flag: uang ini SUDAH dipotong di muka, jadi tak ada
      // besaran turunan yang boleh dipamerkan — kalau "Aman dipakai" muncul
      // di sini, pengguna melihat uangnya lenyap dua kali.
      expect(find.text(l10n.dashboardTiedSafeLabel), findsNothing);
      expect(find.text(l10n.dashboardTiedEyebrow), findsNothing);
    },
  );

  testWidgets('varian B: label + Rp 2.000.000 + detail dua segmen', (
    tester,
  ) async {
    await tester.pumpWidget(harness(varianB));
    await tester.pumpAndSettle();

    expect(find.text('Sebelum gajian'), findsOneWidget);
    expect(find.text('Aman dipakai'), findsOneWidget);
    expect(find.text('Rp 2.000.000'), findsOneWidget);

    // Dua segmen detail = pemisahan bebas vs sudah-dianggarkan.
    expect(find.textContaining('Rp 200.000'), findsOneWidget);
    expect(find.textContaining('terikat tagihan'), findsOneWidget);
    expect(find.textContaining('Rp 500.000'), findsOneWidget);
    expect(find.textContaining('sudah dianggarkan'), findsOneWidget);

    // Bukan varian C.
    expect(find.byKey(negativeIconKey), findsNothing);
    expect(
      find.textContaining('Yuk, cek mana yang bisa diatur ulang'),
      findsNothing,
    );
  });

  testWidgets('varian B tanpa tiedFixed: segmen "sudah dianggarkan" TIDAK '
      'muncul', (tester) async {
    await tester.pumpWidget(harness(varianBTanpaFixed));
    await tester.pumpAndSettle();

    expect(find.text('Aman dipakai'), findsOneWidget);
    expect(find.textContaining('terikat tagihan'), findsOneWidget);

    // tiedFixed == 0 → segmen kosong dilarang tampil (nol data palsu).
    expect(find.textContaining('sudah dianggarkan'), findsNothing);
  });

  testWidgets(
    'varian C saldo TIDAK ter-clamp: nominal −Rp 400.000 TETAP tampil + '
    'ikon + hint hangat',
    (tester) async {
      await tester.pumpWidget(harness(varianC));
      await tester.pumpAndSettle();

      // Saldo pra-clamp 500.000 ≥ 0 → kartu merender angka yang sama dengan
      // yang dipakai menghitung, jadi turunannya bisa dibaca ulang. Negatif
      // TIDAK di-clamp jadi 0 — angkanya jujur.
      expect(find.text('−Rp 400.000'), findsOneWidget);
      // Penanda kedua di samping warna (jangan andalkan warna saja).
      expect(find.byKey(negativeIconKey), findsOneWidget);
      expect(
        find.textContaining('Yuk, cek mana yang bisa diatur ulang'),
        findsOneWidget,
      );
      expect(find.text('Aman dipakai'), findsOneWidget);
    },
  );

  testWidgets(
    'varian C saldo TER-CLAMP: nominal turunan DITAHAN, ikon + hint tetap',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(harness(varianCTerClamp));
      await tester.pumpAndSettle();

      // Kartu merender totalRemaining yang sudah di-clamp ke Rp 0. Kalau
      // "Aman dipakai −Rp 400.000" ikut tampil, pengguna melihat
      // 0 − 100.000 = −400.000 — turunan yang harfiah salah (spec §6.1).
      expect(find.text('−Rp 400.000'), findsNothing);
      expect(find.textContaining('400.000'), findsNothing);
      expect(find.text('Aman dipakai'), findsNothing);

      // Statusnya tetap terbaca, hangat, dengan penanda non-warna.
      expect(find.byKey(negativeIconKey), findsOneWidget);
      expect(
        find.textContaining('Yuk, cek mana yang bisa diatur ulang'),
        findsOneWidget,
      );
      // Fakta yang masih benar tetap ditampilkan apa adanya.
      expect(find.textContaining('Rp 100.000'), findsOneWidget);
      expect(find.text('Sebelum gajian'), findsOneWidget);

      // Klaim yang ditahan di layar tidak boleh balik lewat pembaca layar.
      final node = tester.getSemantics(find.byKey(mainKey));
      expect(node.label, isNot(contains('400.000')));
      expect(node.label, isNot(contains(l10n.dashboardTiedSafeLabel)));
      expect(node.label, contains(l10n.dashboardTiedNegativeHint));

      handle.dispose();
    },
  );

  testWidgets('aturan sembunyi #2: hidden=true → SEMUA nominal jadi Rp •••••• '
      'dan Semantics tidak memuat angka', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(varianB, hidden: true));
    await tester.pumpAndSettle();

    // Tidak satu pun angka boleh lolos — termasuk yang di baris detail.
    expect(find.text('Rp 2.000.000'), findsNothing);
    expect(find.textContaining('2.000.000'), findsNothing);
    expect(find.textContaining('200.000'), findsNothing);
    expect(find.textContaining('500.000'), findsNothing);
    expect(find.text(l10n.dashboardBalanceHidden), findsAtLeastNWidgets(1));

    // Struktur baris tetap: status boleh terlihat, angkanya tidak.
    expect(find.text('Aman dipakai'), findsOneWidget);
    expect(find.text('Sebelum gajian'), findsOneWidget);
    expect(find.textContaining('terikat tagihan'), findsOneWidget);

    // Kebocoran lewat pembaca layar = kebocoran juga.
    final node = tester.getSemantics(find.byKey(mainKey));
    expect(node.label, isNot(contains('2.000.000')));
    expect(node.label, isNot(contains('200.000')));
    expect(node.label, isNot(contains('500.000')));
    expect(node.label, contains(l10n.dashboardBalanceHidden));

    handle.dispose();
  });

  testWidgets('hidden=false: Semantics memuat nominal sebenarnya', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(varianB));
    await tester.pumpAndSettle();

    // Pasangan pengunci test di atas: tanpa ini, widget yang menyamarkan
    // nominal SELAMANYA juga akan lulus.
    final node = tester.getSemantics(find.byKey(mainKey));
    expect(node.label, contains('Rp 2.000.000'));
    expect(node.label, contains('Aman dipakai'));

    handle.dispose();
  });

  testWidgets(
    'nudge §6.2 muncul saat flag true & tap → /budget/edit-settings',
    (tester) async {
      await tester.pumpWidget(harness(nudgeOn));
      await tester.pumpAndSettle();

      expect(find.byKey(nudgeKey), findsOneWidget);
      expect(find.textContaining('Cek lagi, yuk'), findsOneWidget);
      // Hit target minimum Android.
      expect(
        tester.getSize(find.byKey(nudgeKey)).height,
        greaterThanOrEqualTo(48),
      );

      expect(find.text('BUDGET_SETTINGS_MARKER'), findsNothing);
      await tester.tap(find.byKey(nudgeKey));
      await tester.pumpAndSettle();
      expect(find.text('BUDGET_SETTINGS_MARKER'), findsOneWidget);
    },
  );

  testWidgets('nudge tidak muncul saat flag false', (tester) async {
    await tester.pumpWidget(harness(varianB));
    await tester.pumpAndSettle();

    expect(find.byKey(nudgeKey), findsNothing);
    expect(find.textContaining('Cek lagi, yuk'), findsNothing);
  });

  testWidgets('tap baris utama → /bills', (tester) async {
    await tester.pumpWidget(harness(varianB));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(mainKey)).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text('BILLS_PAGE_MARKER'), findsNothing);

    await tester.tap(find.byKey(mainKey));
    await tester.pumpAndSettle();

    expect(find.text('BILLS_PAGE_MARKER'), findsOneWidget);
  });

  testWidgets('dark mode: nominal varian C pakai expenseDark', (tester) async {
    await tester.pumpWidget(
      harness(varianC, theme: ThemeData(brightness: Brightness.dark)),
    );
    await tester.pumpAndSettle();

    final nominal = tester.widget<Text>(find.text('−Rp 400.000'));
    expect(nominal.style?.color, AppColors.expenseDark);
  });

  testWidgets('light mode: nominal varian C pakai warn', (tester) async {
    await tester.pumpWidget(
      harness(varianC, theme: ThemeData(brightness: Brightness.light)),
    );
    await tester.pumpAndSettle();

    final nominal = tester.widget<Text>(find.text('−Rp 400.000'));
    expect(nominal.style?.color, AppColors.warn);
  });

  testWidgets(
    'sembunyi INSTAN: nominal lama tidak tertinggal setelah tombol mata '
    'ditekan',
    (tester) async {
      final hiddenVN = ValueNotifier<bool>(false);
      addTearDown(hiddenVN.dispose);

      await tester.pumpWidget(
        plainHarness(
          ValueListenableBuilder<bool>(
            valueListenable: hiddenVN,
            builder: (context, isHidden, _) =>
                TiedMoneyRow(commitments: varianB, hidden: isHidden),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rp 2.000.000'), findsOneWidget);

      // Tombol mata ditekan → saldo utama kartu hilang SEKETIKA. Baris ini
      // wajib ikut: `AnimatedSwitcher` menahan child lama di tree dan
      // mem-fade-out-nya, jadi tanpa penanganan khusus nominal masih terbaca
      // ~200 ms setelah pengguna minta disembunyikan.
      hiddenVN.value = true;
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Rp 2.000.000'), findsNothing);
      expect(find.textContaining('2.000.000'), findsNothing);
      expect(find.textContaining('200.000'), findsNothing);
      expect(find.textContaining('500.000'), findsNothing);
    },
  );

  testWidgets('skala teks 2.0 di lebar sempit: tidak ada overflow', (
    tester,
  ) async {
    // Lebar produksi tersempit ≈ 360 − 32 (sliver) − 36 (padding kartu).
    await tester.pumpWidget(
      plainHarness(
        const TiedMoneyRow(commitments: varianB, hidden: false),
        width: 292,
        textScaler: const TextScaler.linear(2.0),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Teks tetap utuh — wrap, bukan ellipsis.
    expect(find.text('Aman dipakai'), findsOneWidget);
    expect(find.text('Rp 2.000.000'), findsOneWidget);
  });

  testWidgets('frasa horizon TIDAK memakai register eyebrow "nama besaran"', (
    tester,
  ) async {
    await tester.pumpWidget(harness(varianB));
    await tester.pumpAndSettle();

    // Register kanonik "nama besaran" di kartu ini = `AppTextStyles.caption`
    // (JetBrains Mono 12sp, letterSpacing 0.8) + string UPPERCASE — dipakai
    // "SALDO TERKINI". Kalau frasa horizon ikut memakainya, dalam satu kartu
    // ada DUA eyebrow tak terbedakan dan horizon terbaca sebagai besaran
    // ketiga (dilarang spec §6.1).
    expect(
      l10n.dashboardTiedEyebrow,
      isNot(equals(l10n.dashboardTiedEyebrow.toUpperCase())),
      reason: 'frasa horizon harus sentence case, bukan UPPERCASE',
    );
    expect(
      l10n.dashboardTiedEyebrowInfo,
      isNot(equals(l10n.dashboardTiedEyebrowInfo.toUpperCase())),
    );

    final horizon = tester.widget<Text>(find.text(l10n.dashboardTiedEyebrow));
    expect(horizon.style?.fontFamily, isNot(AppTextStyles.caption.fontFamily));
    expect(horizon.style?.fontFamily, AppTextStyles.bodySmall.fontFamily);
    expect(
      horizon.style?.letterSpacing,
      isNot(AppTextStyles.caption.letterSpacing),
    );
  });
}
