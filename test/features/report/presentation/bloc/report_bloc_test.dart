import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/report/domain/usecases/get_ai_insight_usecase.dart';
import 'package:penyintas_app/features/report/domain/usecases/get_monthly_report_usecase.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_bloc.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_event.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_state.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class MockGetMonthlyReportUseCase extends Mock
    implements GetMonthlyReportUseCase {}

class MockGetAiInsightUseCase extends Mock implements GetAiInsightUseCase {}

class FakeReportEntity extends Fake implements ReportEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeReportEntity());
  });
  late ReportBloc bloc;
  late MockGetMonthlyReportUseCase mockGetMonthlyReport;
  late MockGetAiInsightUseCase mockGetAiInsight;

  final tMonth = DateTime(2025, 11);
  final tReport = ReportEntity(
    month: tMonth,
    totalSpent: 500000,
    totalIncome: 1000000,
    netBalance: 500000,
    categoryBreakdown: const {'food': 500000},
    dailyAverageSpend: 16666.67,
    topCategory: 'food',
    weeklyBreakdown: const [
      WeeklySpendEntity(weekNumber: 1, totalSpent: 500000),
      WeeklySpendEntity(weekNumber: 2, totalSpent: 0),
      WeeklySpendEntity(weekNumber: 3, totalSpent: 0),
      WeeklySpendEntity(weekNumber: 4, totalSpent: 0),
      WeeklySpendEntity(weekNumber: 5, totalSpent: 0),
    ],
    comparedToPreviousMonth: 0.0,
  );

  setUp(() {
    mockGetMonthlyReport = MockGetMonthlyReportUseCase();
    mockGetAiInsight = MockGetAiInsightUseCase();
    bloc = ReportBloc(
      getMonthlyReport: mockGetMonthlyReport,
      getAiInsight: mockGetAiInsight,
    );

    // AI insight returns Left by default so it doesn't interfere
    when(() => mockGetAiInsight(any()))
        .thenAnswer((_) async => Left(ServerFailure()));
  });

  tearDown(() => bloc.close());

  test('initial state is ReportInitial', () {
    expect(bloc.state, const ReportInitial());
  });

  blocTest<ReportBloc, ReportState>(
    'LoadReport emits [Loading, Loaded] on success',
    build: () {
      when(() => mockGetMonthlyReport(tMonth))
          .thenAnswer((_) async => Right(tReport));
      return bloc;
    },
    act: (b) => b.add(LoadReport(tMonth)),
    wait: const Duration(milliseconds: 50),
    expect: () => [
      const ReportLoading(),
      ReportLoaded(report: tReport, selectedMonth: tMonth),
      ReportLoaded(
          report: tReport, selectedMonth: tMonth, isLoadingInsight: true),
      ReportLoaded(report: tReport, selectedMonth: tMonth),
    ],
  );

  blocTest<ReportBloc, ReportState>(
    'LoadReport emits [Loading, Error] on failure',
    build: () {
      when(() => mockGetMonthlyReport(tMonth))
          .thenAnswer((_) async => const Left(CacheFailure('db error')));
      return bloc;
    },
    act: (b) => b.add(LoadReport(tMonth)),
    expect: () => [
      const ReportLoading(),
      const ReportError('db error'),
    ],
  );

  blocTest<ReportBloc, ReportState>(
    'LoadAiInsight updates aiInsights in ReportLoaded',
    build: () {
      when(() => mockGetMonthlyReport(tMonth))
          .thenAnswer((_) async => Right(tReport));
      when(() => mockGetAiInsight(any())).thenAnswer(
        (_) async => Right((['insight1', 'insight2', 'insight3'], null)),
      );
      return bloc;
    },
    act: (b) => b.add(LoadReport(tMonth)),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      const ReportLoading(),
      ReportLoaded(report: tReport, selectedMonth: tMonth),
      ReportLoaded(
        report: tReport,
        selectedMonth: tMonth,
        isLoadingInsight: true,
      ),
      ReportLoaded(
        report: tReport.copyWith(
            aiInsights: ['insight1', 'insight2', 'insight3']),
        selectedMonth: tMonth,
      ),
    ],
  );

  blocTest<ReportBloc, ReportState>(
    'PreviousMonth dispatches LoadReport for previous month',
    build: () {
      when(() => mockGetMonthlyReport(any()))
          .thenAnswer((_) async => Right(tReport));
      return bloc;
    },
    seed: () => ReportLoaded(report: tReport, selectedMonth: tMonth),
    act: (b) => b.add(const PreviousMonth()),
    wait: const Duration(milliseconds: 50),
    verify: (_) {
      verify(() => mockGetMonthlyReport(DateTime(2025, 10))).called(1);
    },
  );

  blocTest<ReportBloc, ReportState>(
    'NextMonth does not dispatch when selectedMonth is current month',
    build: () => bloc,
    seed: () => ReportLoaded(
      report: tReport,
      selectedMonth: DateTime.now(),
    ),
    act: (b) => b.add(const NextMonth()),
    expect: () => [],
  );
}
