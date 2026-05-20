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

/// SynchronousFuture-based delegate to avoid async asset loading in tests.
class _TestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(
        AppLocalizations(locale, const {
          'onboarding_income_title': 'Berapa kiriman bulananmu?',
          'onboarding_income_label': 'Nominal per bulan',
          'onboarding_income_hint': 'Masukkan nominal dalam Rupiah',
          'onboarding_fixed_title': 'Pengeluaran tetap tiap bulan',
          'onboarding_fixed_hint': 'Kos, listrik, internet, dan lainnya',
          'onboarding_date_title': 'Kapan kiriman biasanya masuk?',
          'btn_next': 'Lanjut',
          'btn_back': 'Kembali',
          'btn_save': 'Simpan',
          'loading': 'Memuat...',
          // New keys from #125
          'onboarding_eyebrow_income': 'PEMASUKAN',
          'onboarding_eyebrow_fixed': 'PENGELUARAN TETAP',
          'onboarding_error_invalid_amount': 'Masukkan jumlah kiriman yang valid.',
          'onboarding_error_amount_too_large': 'Jumlah terlalu besar.',
          'onboarding_error_select_date': 'Pilih tanggal kiriman terlebih dahulu.',
          'onboarding_error_empty_expenses': 'Isi paling tidak satu pengeluaran tetap.',
          'onboarding_error_expenses_exceed_income': 'Total pengeluaran melebihi pemasukan. Cek lagi ya.',
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
              'Pengeluaran tetap melebihi pemasukanmu. '
              'Kembali ke langkah sebelumnya dan sesuaikan.',
          'onboarding_emergency_target_label': 'Target dana darurat',
          'onboarding_emergency_per_month': 'Dana darurat per bulan ({pct}% dari sisa)',
          'onboarding_slider_min': '5%',
          'onboarding_slider_max': '25%',
          'category_other': 'Lainnya',
        }),
      );

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

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
      localizationsDelegates: [
        const _TestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id')],
      home: const OnboardingPage(),
    ),
  );
}

void main() {
  late MockOnboardingBloc mockBloc;
  late MockNotificationBloc mockNotifBloc;

  setUp(() {
    mockBloc = MockOnboardingBloc();
    mockNotifBloc = MockNotificationBloc();
    when(() => mockNotifBloc.state).thenReturn(const NotificationInitial());
    when(() => mockNotifBloc.stream)
        .thenAnswer((_) => const Stream.empty());
  });

  group('OnboardingPage — Step 1', () {
    setUp(() {
      when(() => mockBloc.state).thenReturn(const OnboardingStep1());
      when(() => mockBloc.stream)
          .thenAnswer((_) => const Stream.empty());
    });

    testWidgets('renders income preset chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      expect(find.text('Rp 1jt', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 2jt', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 3jt', skipOffstage: false), findsOneWidget);
      expect(find.text('Rp 5jt', skipOffstage: false), findsOneWidget);
    });

    testWidgets('tapping Lanjut without income shows validation error',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      // Tap the 'Lanjut →' button (found by text, skipOffstage ensures it's found)
      await tester.tap(find.text('Lanjut →', skipOffstage: false));
      await tester.pump();

      expect(
        find.text('Masukkan jumlah kiriman yang valid.', skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('OnboardingPage — Step 2', () {
    setUp(() {
      when(() => mockBloc.state).thenReturn(
        const OnboardingStep2(income: 2000000, paymentDate: 25),
      );
      when(() => mockBloc.stream)
          .thenAnswer((_) => const Stream.empty());
    });

    testWidgets('shows back arrow in header when currentStep > 0', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      expect(
        find.byIcon(Icons.arrow_back, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('tapping back arrow dispatches OnboardingBackPressed',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      await tester.tap(
        find.byIcon(Icons.arrow_back, skipOffstage: false),
      );
      await tester.pump();

      verify(() => mockBloc.add(const OnboardingBackPressed())).called(1);
    });
  });

  group('OnboardingPage — Semantics (#129)', () {
    testWidgets('Step 1: date segment chips have button semantics', (tester) async {
      when(() => mockBloc.state).thenReturn(const OnboardingStep1());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      final buttonSemantics = tester
          .widgetList<Semantics>(find.byType(Semantics, skipOffstage: false))
          .where((s) => s.properties.button == true)
          .toList();
      expect(buttonSemantics, isNotEmpty);
    });

    testWidgets('Step 2: expense rows render with localized names', (tester) async {
      // Start at Step 1, then emit Step 2 so the listener fires after
      // the PageController has clients — triggering animateToPage(1).
      when(() => mockBloc.state).thenReturn(const OnboardingStep1());
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const OnboardingStep2(income: 2000000, paymentDate: 25),
        ]),
      );
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump(); // initial Step 1 frame; PageController attaches
      await tester.pump(); // stream delivers Step 2; listener fires → animateToPage(1)
      await tester.pump(const Duration(milliseconds: 350)); // animation completes

      // Expense row labels are rendered with localized strings
      expect(find.text('Kos / Sewa'), findsOneWidget);
      expect(find.text('Listrik & Air'), findsOneWidget);
    });

    testWidgets('Step 1: selected date chip appends dipilih to semantic label',
        (tester) async {
      when(() => mockBloc.state).thenReturn(const OnboardingStep1());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildHarness(
        onboardingBloc: mockBloc,
        notificationBloc: mockNotifBloc,
      ));
      await tester.pump();

      // Tap the "1" date chip to select it
      await tester.tap(find.text('1', skipOffstage: false));
      await tester.pump();

      // Verify the selected chip's Semantics widget has the dipilih suffix
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Tanggal 1, dipilih',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });
  });
}
