// test/widgets/common/financial_slider_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/financial_slider_widget.dart';

// Minimal entity — safe DTL, spending at 60%, non-zero emergency
final _mockEntity = DashboardEntity(
  dailyBudget: 50000,
  spentToday: 20000,
  remainingToday: 30000,
  totalMonthlyBudget: 1500000,
  totalSpentThisMonth: 900000,
  totalRemaining: 600000,
  daysToLive: 23,
  remainingDays: 30,
  avgDailySpend: 30000,
  status: BudgetStatus.safe,
  lastUpdated: DateTime(2026, 5, 29),
  todayTransactions: const [],
  emergencyFundMonthly: 150000,
);

// Synchronous delegate wrapping a pre-loaded AppLocalizations instance.
// Required because AppLocalizations.delegate.load() uses rootBundle.loadString()
// which is backed by a platform channel — after the first test's fakeAsync zone
// completes, subsequent tests cannot drive the async asset load via pump().
// Preloading once in setUpAll and forwarding through a sync delegate fixes this.
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

GoRouter _router(
  DashboardEntity entity, {
  BudgetOverviewEntity? budgetOverview,
}) => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => Scaffold(
        body: FinancialSliderWidget(
          entity: entity,
          budgetOverview: budgetOverview,
        ),
      ),
    ),
    GoRoute(path: '/dtl', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/emergency', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/transactions', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/budget', builder: (_, _) => const SizedBox()),
  ],
);

BudgetOverviewEntity _budgetOverview({
  int totalLimitSet = 500000,
  int totalSpentInLimited = 200000,
}) => BudgetOverviewEntity(
  monthlyIncome: 3000000,
  totalFixedExpenses: 1000000,
  emergencyFundMonthly: 200000,
  totalSpendable: 1800000,
  categoryItems: const [],
  totalLimitSet: totalLimitSet,
  totalSpentInLimited: totalSpentInLimited,
  overallStatus: BudgetStatus.safe,
  remainingDays: 15,
  daysElapsed: 5,
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  Widget buildWidget(
    DashboardEntity entity, {
    BudgetOverviewEntity? budgetOverview,
    ThemeData? theme,
  }) => MaterialApp.router(
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    theme: theme,
    localizationsDelegates: [
      _SyncL10nDelegate(l10n),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: _router(entity, budgetOverview: budgetOverview),
  );

  Widget harness(DashboardEntity entity, {ThemeData? theme}) =>
      buildWidget(entity, theme: theme);

  group('FinancialSliderWidget', () {
    testWidgets('renders without exception', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(_mockEntity));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows DTL label (HARI TERSISA)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(_mockEntity));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // DTL slide is the first (index 0) and starts visible
      expect(find.text('HARI TERSISA'), findsOneWidget);
    });

    testWidgets('contains a PageView with 4 slides', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(_mockEntity));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PageView), findsOneWidget);
      // Slides 0 (HARI TERSISA) and 1 (PENGELUARAN BULAN INI) are rendered
      // initially (PageView with viewportFraction 0.82 builds current + next).
      expect(find.text('HARI TERSISA'), findsOneWidget);
      expect(find.text('PENGELUARAN BULAN INI'), findsOneWidget);
      // Swipe once to expose slide 2 (ANGGARAN KATEGORI — Budget) into the render tree
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('ANGGARAN KATEGORI'), findsOneWidget);
      // Swipe again to expose slide 3 (ALOKASI DARURAT — Emergency)
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('ALOKASI DARURAT'), findsOneWidget);
    });

    testWidgets('renders in dark mode without exception', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        harness(_mockEntity, theme: ThemeData(brightness: Brightness.dark)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('auto-plays to next slide after 4 seconds', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(_mockEntity));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Slide 1 (Spending) starts as the right peek — its label is right of center.
      final screenCenterX = 400.0; // physicalSize.width / 2
      final initialCenter = tester.getCenter(
        find.text('PENGELUARAN BULAN INI'),
      );
      expect(initialCenter.dx, greaterThan(screenCenterX));

      // Advance past the 4s auto-play interval and the 440ms animation.
      await tester.pump(const Duration(seconds: 4, milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      // After auto-advance, Spending card is centred. The label is left-aligned
      // within the card, so its X shifts leftward (peek→active direction).
      final afterCenter = tester.getCenter(find.text('PENGELUARAN BULAN INI'));
      expect(afterCenter.dx, lessThan(initialCenter.dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely with all-zero entity', (tester) async {
      // Guards: remainingDays==0, totalMonthlyBudget==0, emergTotal==0
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final zeroEntity = DashboardEntity(
        dailyBudget: 0,
        spentToday: 0,
        remainingToday: 0,
        totalMonthlyBudget: 0,
        totalSpentThisMonth: 0,
        totalRemaining: 0,
        daysToLive: 0,
        remainingDays: 0,
        avgDailySpend: 0,
        status: BudgetStatus.danger,
        lastUpdated: DateTime(2026, 5, 29),
        todayTransactions: const [],
        emergencyFundMonthly: 0,
      );

      await tester.pumpWidget(harness(zeroEntity));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('HARI TERSISA'), findsOneWidget);
    });

    testWidgets('FinancialSliderWidget shows budget data state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildWidget(
          _mockEntity,
          budgetOverview: _budgetOverview(
            totalLimitSet: 500000,
            totalSpentInLimited: 200000,
          ),
        ),
      );
      await tester.pump();

      // Navigate to budget slide (index 2) by swiping twice
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();

      // Budget slide should show remaining amount (500000 - 200000 = 300000)
      expect(find.textContaining('300'), findsWidgets);
      // And percentage used: 40% (200000/500000)
      expect(find.textContaining('40%'), findsOneWidget);
    });
  });
}
