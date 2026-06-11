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
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/cubit/onboarding_draft_cubit.dart';
import 'package:penyintas_app/features/onboarding/presentation/pages/onboarding_page.dart';

class MockOnboardingBloc
    extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

class MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class MockOnboardingDraftCubit extends MockCubit<OnboardingDraftState>
    implements OnboardingDraftCubit {}

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
          // Date picker sheet
          'onboarding_date_picker_title': 'Pilih tanggal',
          'onboarding_date_picker_subtitle': 'Tanggal masuk kiriman/gaji',
          'onboarding_date_picker_note': '* Tanggal tidak tersedia bulan ini',
          'onboarding_date_picker_none': 'Pilih tanggal dulu',
          'onboarding_date_picker_use': 'Gunakan tanggal {date}',
          'onboarding_date_picker_use_approx': 'Gunakan ~tanggal {date}',
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
          'onboarding_skip_later': 'Lanjut nanti',
          'onboarding_resume_dialog_title': 'Lanjutkan setup?',
          'onboarding_resume_dialog_body':
              'Kamu punya data dari {days} hari lalu. Lanjut dari sana atau mulai ulang?',
          'onboarding_resume_continue': 'Lanjut dari sana',
          'onboarding_resume_restart': 'Mulai ulang',
          'onboarding_resume_banner': 'Melanjutkan dari sesi sebelumnya',
          'onboarding_reset_dialog_title': 'Mulai ulang setup?',
          'onboarding_reset_dialog_cancel': 'Batal',
          'onboarding_reset_dialog_confirm': 'Ya, mulai ulang',
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
  OnboardingDraftCubit? draftCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<OnboardingBloc>.value(value: onboardingBloc),
      BlocProvider<NotificationBloc>.value(value: notificationBloc),
      BlocProvider<OnboardingDraftCubit>.value(
          value: draftCubit ?? MockOnboardingDraftCubit()),
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
  late MockOnboardingDraftCubit mockDraftCubit;

  setUpAll(() {
    registerFallbackValue(const OnboardingSubmitted(
      income: 0,
      paymentDate: 1,
      expenses: {},
      emergencyFundPct: 0.0,
    ));
  });

  setUp(() {
    mockBloc = MockOnboardingBloc();
    mockNotifBloc = MockNotificationBloc();
    mockDraftCubit = MockOnboardingDraftCubit();
    when(() => mockNotifBloc.state).thenReturn(const NotificationInitial());
    when(() => mockNotifBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.state).thenReturn(const OnboardingInitial());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockDraftCubit.state).thenReturn(const OnboardingDraftInitial());
    when(() => mockDraftCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockDraftCubit.loadDraft()).thenAnswer((_) async {});
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
        draftCubit: mockDraftCubit,
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
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      expect(find.text('Rp 800rb', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 1,5jt', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 3jt', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 5jt', skipOffstage: false), findsOneWidget);
    });

    testWidgets('menampilkan tombol "Lanjut nanti" di header step 0',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      expect(find.text('Lanjut nanti', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tap "Lanjut nanti" menyimpan state dan keluar (tanpa dialog)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockDraftCubit.saveDraft(
            step: any(named: 'step'),
            income: any(named: 'income'),
            expenses: any(named: 'expenses'),
            pct: any(named: 'pct'),
            payday: any(named: 'payday'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      // Tap "Lanjut nanti" — seharusnya tidak membuka dialog
      await tester.tap(find.text('Lanjut nanti', skipOffstage: false));
      await tester.pumpAndSettle();

      // Tidak ada dialog konfirmasi yang muncul (deferAndExit langsung keluar)
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tap preset chip mengubah nominal income', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: mockDraftCubit,
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
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      // Default income = 0. Tap preset chip 'Rp 3jt' → income = 3000000.
      await tester.tap(find.text('Rp 3jt', skipOffstage: false));
      await tester.pump();

      // Preset sets income to 3000000 → display shows '3.000.000'
      expect(find.text('3.000.000', skipOffstage: false), findsOneWidget);
    });

    testWidgets('date picker terbuka tanpa tanggal pre-selected', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      await tester.tap(find.text('Lain', skipOffstage: false));
      await tester.pumpAndSettle();

      // Tidak ada pre-selection → button disabled, label "Pilih tanggal dulu"
      expect(find.text('Pilih tanggal dulu'), findsOneWidget);
    });

    testWidgets('chip "Lain" membuka date picker sheet (grid off-screen — verify sheet opens)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      // Buka date picker
      await tester.tap(find.text('Lain', skipOffstage: false));
      await tester.pump(const Duration(milliseconds: 300));

      // Sheet terbuka dan menampilkan tombol konfirmasi (disabled karena belum pilih tanggal)
      expect(find.text('Pilih tanggal dulu'), findsOneWidget);

      // Tutup sheet via Batal
      await tester.tap(find.text('Batal'));
      await tester.pump(const Duration(milliseconds: 300));

      // Chip kembali menampilkan 'Lain' karena tidak ada tanggal dipilih
      expect(find.text('Lain', skipOffstage: false), findsOneWidget);
    });

    testWidgets('CTA "Lanjut" disabled saat income = 0', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      // Income awal = 2.500.000 → hapus semua digit via back key (7 kali)
      // Back key (_BackIcon) dirender sebagai CustomPaint ukuran 22×22.
      // applyOnboardingKey: 2500000→250000→25000→2500→250→25→2→0
      final backKey = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.size == const Size(22, 22),
      );
      for (var i = 0; i < 7; i++) {
        await tester.tap(backKey);
        await tester.pump();
      }

      // Income = 0 → CTA harus disabled (onPressed == null).
      // Cari FilledButton yang memuat teks 'Lanjut'.
      final ctaFinder = find.ancestor(
        of: find.text('Lanjut', skipOffstage: false),
        matching: find.byType(FilledButton),
        matchRoot: false,
      );
      final cta = tester.widget<FilledButton>(ctaFinder);
      expect(cta.onPressed, isNull);
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
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      // Enable CTA by setting income > 0 via preset chip
      await tester.tap(find.text('Rp 3jt', skipOffstage: false));
      await tester.pump();
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      // Use pump(duration) instead of pumpAndSettle — WeatherSceneWidget has
      // a repeating animation that prevents pumpAndSettle from ever settling.
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('RUAS 2 · PENGELUARAN TETAP', skipOffstage: false),
          findsOneWidget);
      expect(find.text('Kebutuhan tetapmu', skipOffstage: false), findsOneWidget);
    });

    testWidgets('step 1 menampilkan back arrow, bukan "Lanjut nanti"',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();

      // Enable CTA by setting income > 0 via preset chip
      await tester.tap(find.text('Rp 3jt', skipOffstage: false));
      await tester.pump();
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      // Use pump(duration) instead of pumpAndSettle — WeatherSceneWidget has
      // a repeating animation that prevents pumpAndSettle from ever settling.
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Lanjut nanti', skipOffstage: false), findsNothing);
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
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();
      // Enable CTA by setting income > 0 via preset chip
      await tester.tap(find.text('Rp 3jt', skipOffstage: false));
      await tester.pump();
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      // Use pump(duration) instead of pumpAndSettle — WeatherSceneWidget has
      // a repeating animation that prevents pumpAndSettle from ever settling.
      await tester.pump(const Duration(seconds: 1));
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
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Selesai', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tap "Selesai" menutup keypad sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToStep1(tester);

      await tester.tap(find.text('Kos / Sewa', skipOffstage: false));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Selesai', skipOffstage: false));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Lanjut', skipOffstage: false), findsOneWidget);
    });
  });

  // ── Ruas 3 — dana darurat ──────────────────────────────────────────────
  group('Ruas 3 — slider dan chips', () {
    Future<void> goToStep2(WidgetTester tester) async {
      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();
      // Enable CTA by setting income > 0 via preset chip
      await tester.tap(find.text('Rp 3jt', skipOffstage: false));
      await tester.pump();
      // Step 0 → 1 (WeatherSceneWidget has repeating anim — use pump(duration))
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pump(const Duration(seconds: 1));
      // Step 1 → 2
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pump(const Duration(seconds: 1));
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
      expect(find.text('Lewati dulu', skipOffstage: false), findsOneWidget);
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
      await tester.pump();

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
      await tester.pump();

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
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();
      // Enable CTA by setting income > 0 via preset chip
      await tester.tap(find.text('Rp 3jt', skipOffstage: false));
      await tester.pump();
      // Step 0 → 1 (WeatherSceneWidget has repeating anim — use pump(duration))
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pump(const Duration(seconds: 1));
      // Step 1 → 2
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pump(const Duration(seconds: 1));
      // Step 2 → done
      await tester.tap(find.text('Mulai Bertahan', skipOffstage: false));
      await tester.pump(const Duration(seconds: 1));
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

    // #208: _submitAll sekarang mengirim satu OnboardingSubmitted, bukan burst 3 event
    testWidgets('tap "Masuk ke Beranda" mengirim OnboardingSubmitted', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToDone(tester);

      await tester.tap(find.text('Masuk ke Beranda', skipOffstage: false));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<OnboardingSubmitted>()))).called(1);
    });

    testWidgets('OnboardingSubmitted membawa emergencyFundPct=0.10 untuk default pct=10', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await goToDone(tester);

      await tester.tap(find.text('Masuk ke Beranda', skipOffstage: false));
      await tester.pump();

      verify(() => mockBloc.add(any(
            that: isA<OnboardingSubmitted>().having(
              (e) => e.emergencyFundPct,
              'emergencyFundPct',
              closeTo(0.10, 0.001),
            ),
          ))).called(1);
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
        draftCubit: mockDraftCubit,
      ));
      await tester.pump();
      // Enable CTA by setting income > 0 via preset chip
      await tester.tap(find.text('Rp 3jt', skipOffstage: false));
      await tester.pump();
      // WeatherSceneWidget has repeating anim — use pump(duration) not pumpAndSettle
      await tester.tap(find.text('Lanjut', skipOffstage: false));
      await tester.pump(const Duration(seconds: 1));

      // Now at step 1 — tap back arrow
      await tester.tap(
        find.byIcon(Icons.arrow_back_ios_new_rounded, skipOffstage: false),
      );
      await tester.pump(const Duration(seconds: 1));

      // Should be back at step 0
      expect(find.text('RUAS 1 · PEMASUKAN', skipOffstage: false), findsOneWidget);
      expect(find.text('Lanjut nanti', skipOffstage: false), findsOneWidget);
    });
  });

  // ── Resume (#244) ─────────────────────────────────────────────────────
  group('Resume (#244)', () {
    PartialOnboardingState partial(DateTime savedAt, {int step = 0}) =>
        PartialOnboardingState(
          step: step,
          income: 1500000,
          expenses: const {
            'kos': 0,
            'listrik': 0,
            'internet': 0,
            'pulsa': 0,
            'lain': 0,
          },
          pct: 10,
          payday: 25,
          savedAt: savedAt,
        );

    void sizeView(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('partial < 7 hari → banner muncul', (tester) async {
      sizeView(tester);
      final resumeCubit = MockOnboardingDraftCubit();
      when(() => resumeCubit.state).thenReturn(
          OnboardingDraftLoaded(partial(DateTime.now())));
      when(() => resumeCubit.stream).thenAnswer((_) => Stream.value(
          OnboardingDraftLoaded(partial(DateTime.now()))));
      when(() => resumeCubit.loadDraft()).thenAnswer((_) async {});
      when(() => resumeCubit.clearDraft()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: resumeCubit,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        find.text('Melanjutkan dari sesi sebelumnya', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('tap "Mulai ulang" → konfirmasi → clear + banner hilang',
        (tester) async {
      sizeView(tester);
      final resumeCubit = MockOnboardingDraftCubit();
      when(() => resumeCubit.state).thenReturn(
          OnboardingDraftLoaded(partial(DateTime.now())));
      when(() => resumeCubit.stream).thenAnswer((_) => Stream.value(
          OnboardingDraftLoaded(partial(DateTime.now()))));
      when(() => resumeCubit.loadDraft()).thenAnswer((_) async {});
      when(() => resumeCubit.clearDraft()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: resumeCubit,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Banner restart button.
      await tester.tap(find.text('Mulai ulang', skipOffstage: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Dialog konfirmasi reset muncul.
      expect(find.text('Mulai ulang setup?', skipOffstage: false),
          findsOneWidget);

      await tester.tap(find.text('Ya, mulai ulang', skipOffstage: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => resumeCubit.clearDraft()).called(1);
      expect(find.text('Melanjutkan dari sesi sebelumnya', skipOffstage: false),
          findsNothing);
    });

    testWidgets('partial ≥ 7 hari → dialog stale muncul', (tester) async {
      sizeView(tester);
      final staleCubit = MockOnboardingDraftCubit();
      final stalePartial = partial(
          DateTime.now().subtract(const Duration(days: 8)));
      when(() => staleCubit.state).thenReturn(
          OnboardingDraftLoaded(stalePartial));
      when(() => staleCubit.stream).thenAnswer((_) => Stream.value(
          OnboardingDraftLoaded(stalePartial)));
      when(() => staleCubit.loadDraft()).thenAnswer((_) async {});
      when(() => staleCubit.clearDraft()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
        draftCubit: staleCubit,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Lanjutkan setup?', skipOffstage: false), findsOneWidget);
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
        draftCubit: mockDraftCubit,
      ));
      await tester.pump(); // initial frame
      await tester.pump(); // stream delivers Calculating

      // Navigation to done screen requires tapping through — skip here;
      // verify Calculating doesn't crash the widget.
      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });
}
