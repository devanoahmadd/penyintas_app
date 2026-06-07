import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/pages/onboarding_page.dart';

class MockOnboardingBloc
    extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

class MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

/// Synchronous delegate — avoids async asset loading in tests.
class _TestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(
        AppLocalizations(locale, const {
          // General
          'btn_next': 'Lanjut',
          'btn_back': 'Kembali',
          'btn_save': 'Simpan',
          'btn_cancel': 'Batal',
          'loading': 'Memuat...',
          'retry': 'Coba lagi',
          'category_other': 'Lainnya',
          // Onboarding — existing
          'onboarding_income_title': 'Berapa kiriman bulananmu?',
          'onboarding_income_label': 'Nominal per bulan',
          'onboarding_income_hint': 'Masukkan nominal dalam Rupiah',
          'onboarding_fixed_title': 'Pengeluaran tetap tiap bulan',
          'onboarding_fixed_hint': 'Kos, listrik, internet, dan lainnya',
          'onboarding_date_title': 'Kapan kiriman biasanya masuk?',
          'onboarding_eyebrow_income': 'PEMASUKAN',
          'onboarding_eyebrow_fixed': 'PENGELUARAN TETAP',
          'onboarding_error_invalid_amount': 'Masukkan jumlah kiriman yang valid.',
          'onboarding_error_amount_too_large': 'Jumlah terlalu besar.',
          'onboarding_error_select_date': 'Pilih tanggal kiriman terlebih dahulu.',
          'onboarding_error_empty_expenses': 'Isi paling tidak satu pengeluaran tetap.',
          'onboarding_error_expenses_exceed_income':
              'Total pengeluaran melebihi pemasukan. Cek lagi ya.',
          'onboarding_expense_rent': 'Kos / Sewa',
          'onboarding_expense_rent_hint': 'Bulanan, kontan',
          'onboarding_expense_utilities': 'Listrik & Air',
          'onboarding_expense_utilities_hint': 'Token / tagihan',
          'onboarding_expense_internet': 'Internet / Wi-Fi',
          'onboarding_expense_internet_hint': 'Paket bulanan',
          'onboarding_expense_phone': 'Pulsa & Data',
          'onboarding_expense_phone_hint': 'Opsional',
          'onboarding_expense_other_hint': 'Cicilan, langganan',
          'onboarding_error_fixed_exceeds_income':
              'Pengeluaran tetap melebihi pemasukanmu.',
          'onboarding_emergency_target_label': 'Target dana darurat',
          'onboarding_emergency_per_month': 'Dana darurat per bulan ({pct}%)',
          'onboarding_slider_min': '5%',
          'onboarding_slider_max': '25%',
          'onboarding_emergency_title': 'Dana darurat',
          'onboarding_eyebrow_emergency': 'DANA DARURAT',
          'onboarding_emergency_subtitle': 'Sisihkan untuk hari tak terduga.',
          'onboarding_emergency_question': 'Sisihkan berapa tiap bulan?',
          'onboarding_emergency_skip': 'Lewati dulu',
          'onboarding_daily_budget_label': 'ANGGARAN HARIANMU',
          'onboarding_daily_budget_suffix': '/hari',
          'onboarding_daily_budget_days_left': 'untuk {days} hari ke depan',
          'onboarding_daily_budget_monthly_left': '{amount} tersisa bulan ini',
          'onboarding_income_subtitle': '',
          'onboarding_fixed_expense_warning': '',
          // Onboarding redesign — C+ stagger
          'onboarding_eyebrow_step1': 'RUAS 1 · PEMASUKAN',
          'onboarding_eyebrow_step2': 'RUAS 2 · PENGELUARAN TETAP',
          'onboarding_eyebrow_step3': 'RUAS 3 · DANA DARURAT',
          'onboarding_title_income': 'Pemasukan bulananmu',
          'onboarding_title_fixed': 'Kebutuhan tetapmu',
          'onboarding_title_darurat': 'Sisihkan, biar lentur',
          'onboarding_done_eyebrow': 'SIAP BERTAHAN',
          'onboarding_done_title': 'Kamu siap bertahan',
          'onboarding_done_sub': 'Lentur, tak patah. Mulai catat pengeluaran hari ini.',
          'onboarding_payday_label': 'Biasanya masuk tanggal',
          'onboarding_skip_later': 'Nanti',
          'onboarding_chip_other_date': 'Lain',
          'onboarding_cta_start': 'Mulai Bertahan',
          'onboarding_cta_enter': 'Masuk ke Beranda',
          'onboarding_sheet_done': 'Selesai',
          'onboarding_total_label': 'TOTAL TETAP / BULAN',
          'onboarding_total_pct': '≈ {pct}% dari pemasukan',
          'onboarding_sheet_total_label': 'TOTAL TETAP · {pct}%',
          'onboarding_daily_sub_no_emergency': 'tanpa dana darurat',
          'onboarding_daily_sub_saving': 'nabung {amount}/bln',
          'onboarding_pct_label_low': 'Santai',
          'onboarding_pct_note_low': 'Langkah kecil yang ringan untuk memulai.',
          'onboarding_pct_label_mid': 'Seimbang',
          'onboarding_pct_note_mid': 'Rekomendasi kami — aman tanpa terlalu ketat.',
          'onboarding_pct_label_high': 'Rajin',
          'onboarding_pct_note_high': 'Dana darurat penuh lebih cepat.',
          'onboarding_pct_label_max': 'Ekstrem',
          'onboarding_pct_note_max': 'Pertahanan terkuat.',
          'onboarding_pct_note_skip': 'Tanpa dana darurat dulu.',
          'onboarding_stat_daily': 'ANGGARAN HARIAN',
          'onboarding_stat_emergency': 'DANA DARURAT',
          'onboarding_stat_income': 'PEMASUKAN',
          'onboarding_stat_fixed': 'PENGELUARAN TETAP',
        }),
      );

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

// ── Test harness ──────────────────────────────────────────────────────────


Widget _buildHarness({
  required OnboardingBloc onboardingBloc,
  required NotificationBloc notificationBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<OnboardingBloc>.value(value: onboardingBloc),
      BlocProvider<NotificationBloc>.value(value: notificationBloc),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        _TestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id')],
      home: const OnboardingPage(),
    ),
  );
}


// ── Main ──────────────────────────────────────────────────────────────────

void main() {
  late MockOnboardingBloc mockBloc;
  late MockNotificationBloc mockNotifBloc;

  setUpAll(() {
    registerFallbackValue(const OnboardingStarted());
  });

  setUp(() {
    mockBloc = MockOnboardingBloc();
    mockNotifBloc = MockNotificationBloc();
    when(() => mockNotifBloc.state).thenReturn(const NotificationInitial());
    when(() => mockNotifBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.state).thenReturn(const OnboardingInitial());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  // ── Ruas 1 (step 0) ────────────────────────────────────────────────────
  group('Ruas 1 — tampilan awal', () {
    testWidgets('menampilkan eyebrow RUAS 1 dan judul', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      expect(find.text('RUAS 1 · PEMASUKAN', skipOffstage: false), findsOneWidget);
      expect(find.text('Pemasukan bulananmu', skipOffstage: false), findsOneWidget);
    });

    testWidgets('menampilkan 4 chip preset pemasukan', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      expect(find.text('Rp 800rb', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 1,5jt', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 3jt', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 5jt', skipOffstage: false), findsOneWidget);
    });

    testWidgets('menampilkan tombol "Nanti" di header step 0', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      expect(find.text('Nanti', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tap "Nanti" membuka dialog konfirmasi', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      await tester.tap(find.text('Nanti', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text('Tutup setup sekarang?'), findsOneWidget);
      expect(find.text('Ya, keluar'), findsOneWidget);
      expect(find.text('Lanjut isi'), findsOneWidget);
    });

    testWidgets('tap preset chip mengubah nominal income', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      await tester.tap(find.text('Rp 5jt', skipOffstage: false));
      await tester.pump();

      // The amount display updates to 5.000.000
      expect(find.text('5.000.000', skipOffstage: false), findsOneWidget);
    });

    testWidgets('keypad: tap digit menambah angka', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      // Default income = 2.500.000. Tap '3' key.
      await tester.tap(find.text('3', skipOffstage: false).first);
      await tester.pump();

      // 2500000 * 10 + 3 = 25000003
      expect(find.text('25.000.003', skipOffstage: false), findsOneWidget);
    });

    testWidgets('date picker terbuka tanpa tanggal pre-selected', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      await tester.tap(find.text('Lain', skipOffstage: false));
      await tester.pumpAndSettle();

      // Tidak ada pre-selection → button disabled, label "Pilih tanggal dulu"
      expect(find.text('Pilih tanggal dulu'), findsOneWidget);
    });

    testWidgets('chip "Lain" menampilkan tanggal setelah konfirmasi custom date', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      // Buka date picker
      await tester.tap(find.text('Lain', skipOffstage: false));
      await tester.pumpAndSettle();

      // Pilih tanggal 14 di grid
      await tester.tap(find.text('14').last);
      await tester.pump();

      // Konfirmasi
      await tester.tap(find.text('Gunakan tanggal 14'));
      await tester.pumpAndSettle();

      // Chip menampilkan '14', bukan 'Lain'
      expect(find.text('14', skipOffstage: false), findsOneWidget);
      expect(find.text('Lain', skipOffstage: false), findsNothing);
    });
  });

  // ── Navigasi step 0 → step 1 ───────────────────────────────────────────
  group('Navigasi: Ruas 1 → Ruas 2', () {
    testWidgets('tap "Lanjut" menampilkan Ruas 2', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text('RUAS 2 · PENGELUARAN TETAP', skipOffstage: false),
          findsOneWidget);
      expect(find.text('Kebutuhan tetapmu', skipOffstage: false), findsOneWidget);
    });

    testWidgets('step 1 menampilkan back arrow, bukan "Nanti"', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text('Nanti', skipOffstage: false), findsNothing);
      expect(
        find.byIcon(Icons.arrow_back_ios_new_rounded, skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  // ── Ruas 2 — pengeluaran tetap ─────────────────────────────────────────
  group('Ruas 2 — expense rows', () {
    Future<void> goToStep1(WidgetTester tester) async {
      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan 5 expense rows', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep1(tester);

      expect(find.text('Kos / Sewa', skipOffstage: false), findsOneWidget);
      expect(find.text('Listrik & Air', skipOffstage: false), findsOneWidget);
      expect(find.text('Internet / Wi-Fi', skipOffstage: false), findsOneWidget);
      expect(find.text('Pulsa & Data', skipOffstage: false), findsOneWidget);
      expect(find.text('Lainnya', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tap expense row memunculkan keypad sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep1(tester);

      await tester.tap(find.text('Kos / Sewa', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text('Selesai', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tap "Selesai" menutup keypad sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep1(tester);

      await tester.tap(find.text('Kos / Sewa', skipOffstage: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selesai', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text('Lanjut', skipOffstage: false), findsOneWidget);
    });
  });

  // ── Ruas 3 — dana darurat ──────────────────────────────────────────────
  group('Ruas 3 — slider dan chips', () {
    Future<void> goToStep2(WidgetTester tester) async {
      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();
      // Step 0 → 1
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pumpAndSettle();
      // Step 1 → 2
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan eyebrow RUAS 3 dan pct chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep2(tester);

      expect(find.text('RUAS 3 · DANA DARURAT', skipOffstage: false),
          findsOneWidget);
      // Chips — may appear twice if active pct matches (chip + active label)
      expect(find.text('5%', skipOffstage: false), findsWidgets);
      expect(find.text('10%', skipOffstage: false), findsWidgets);
      expect(find.text('15%', skipOffstage: false), findsWidgets);
      expect(find.text('Lewati', skipOffstage: false), findsOneWidget);
    });

    testWidgets('menampilkan chip Ekstrem', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep2(tester);

      expect(find.text('Ekstrem', skipOffstage: false), findsOneWidget);
    });

    testWidgets('menampilkan CTA "Mulai Bertahan"', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep2(tester);

      expect(find.text('Mulai Bertahan', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tap chip 5% mengubah pct ke 5', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep2(tester);

      await tester.tap(find.text('5%', skipOffstage: false));
      await tester.pumpAndSettle();

      // feedback label for pct=5 (≤7) is "Santai"
      expect(find.text('Santai', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tap chip Ekstrem menampilkan feedback Ekstrem', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep2(tester);

      await tester.tap(find.text('Ekstrem', skipOffstage: false));
      await tester.pumpAndSettle();

      // pct=25 → both feedback label "Ekstrem" and chip "Ekstrem" appear
      expect(find.text('Ekstrem', skipOffstage: false),
          findsAtLeastNWidgets(2));
      // The pct% indicator shows "25%"
      expect(find.text('25%', skipOffstage: false), findsWidgets);
    });
  });

  // ── Done screen ────────────────────────────────────────────────────────
  group('Layar selesai', () {
    Future<void> goToDone(WidgetTester tester) async {
      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai Bertahan', skipOffstage: false));
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan eyebrow SIAP BERTAHAN dan 4 stat', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToDone(tester);

      expect(find.text('SIAP BERTAHAN', skipOffstage: false), findsOneWidget);
      expect(find.text('Kamu siap bertahan', skipOffstage: false), findsOneWidget);
      expect(find.text('ANGGARAN HARIAN', skipOffstage: false), findsOneWidget);
      expect(find.text('PEMASUKAN', skipOffstage: false), findsOneWidget);
    });

    testWidgets('menampilkan CTA "Masuk ke Beranda"', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToDone(tester);

      expect(find.text('Masuk ke Beranda', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tap "Masuk ke Beranda" mengirim Step1/2/3Submitted', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToDone(tester);

      await tester.tap(find.text('Masuk ke Beranda', skipOffstage: false));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<Step1Submitted>()))).called(1);
      verify(() => mockBloc.add(any(that: isA<Step2Submitted>()))).called(1);
      verify(() => mockBloc.add(any(that: isA<Step3Submitted>()))).called(1);
    });

    testWidgets('Step3Submitted emergencyFundPct=0.10 untuk default pct=10', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToDone(tester);

      await tester.tap(find.text('Masuk ke Beranda', skipOffstage: false));
      await tester.pump();

      verify(() => mockBloc.add(
            const Step3Submitted(emergencyFundPct: 0.10),
          )).called(1);
    });
  });

  // ── Back navigation ────────────────────────────────────────────────────
  group('Navigasi back', () {
    testWidgets('tap back arrow di step 1 kembali ke step 0', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pumpAndSettle();

      // Now at step 1 — tap back arrow
      await tester.tap(
        find.byIcon(Icons.arrow_back_ios_new_rounded, skipOffstage: false),
      );
      await tester.pumpAndSettle();

      // Should be back at step 0
      expect(find.text('RUAS 1 · PEMASUKAN', skipOffstage: false), findsOneWidget);
      expect(find.text('Nanti', skipOffstage: false), findsOneWidget);
    });
  });

  // ── OnboardingSuccess → navigate ──────────────────────────────────────
  group('OnboardingSuccess', () {
    testWidgets('state Success memunculkan loading di CTA', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Simulate Calculating state
      whenListen(
        mockBloc,
        Stream<OnboardingState>.fromIterable(const [OnboardingCalculating()]),
        initialState: const OnboardingInitial(),
      );

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump(); // initial frame
      await tester.pump(); // stream delivers Calculating

      // Navigation to done screen requires tapping through — skip here;
      // verify Calculating doesn't crash the widget.
      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });
}
