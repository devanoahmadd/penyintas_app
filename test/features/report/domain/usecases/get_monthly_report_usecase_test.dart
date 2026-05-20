import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/report/domain/repositories/report_repository.dart';
import 'package:penyintas_app/features/report/domain/usecases/get_monthly_report_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late GetMonthlyReportUseCase useCase;
  late MockReportRepository mockRepo;

  final tMonth = DateTime(2025, 11);
  final tReport = ReportEntity(
    month: tMonth,
    totalSpent: 500000,
    totalIncome: 1000000,
    netBalance: 500000,
    categoryBreakdown: const {TransactionCategory.food: 300000},
    dailyAverageSpend: 16666.67,
    topCategory: TransactionCategory.food,
    weeklyBreakdown: const [
      WeeklySpendEntity(weekNumber: 1, totalSpent: 200000),
      WeeklySpendEntity(weekNumber: 2, totalSpent: 150000),
      WeeklySpendEntity(weekNumber: 3, totalSpent: 100000),
      WeeklySpendEntity(weekNumber: 4, totalSpent: 50000),
      WeeklySpendEntity(weekNumber: 5, totalSpent: 0),
    ],
    comparedToPreviousMonth: 0.0,
  );

  setUp(() {
    mockRepo = MockReportRepository();
    useCase = GetMonthlyReportUseCase(mockRepo);
  });

  test('returns Right(report) when repo succeeds', () async {
    when(() => mockRepo.getMonthlyReport(tMonth))
        .thenAnswer((_) async => Right(tReport));

    final result = await useCase(tMonth);

    expect(result, Right<Failure, ReportEntity>(tReport));
    verify(() => mockRepo.getMonthlyReport(tMonth)).called(1);
  });

  test('returns Left(Failure) when repo fails', () async {
    when(() => mockRepo.getMonthlyReport(tMonth))
        .thenAnswer((_) async => const Left(CacheFailure('error')));

    final result = await useCase(tMonth);

    expect(result, const Left<Failure, ReportEntity>(CacheFailure('error')));
  });

  test('forwards month param to repo', () async {
    final specificMonth = DateTime(2024, 3);
    when(() => mockRepo.getMonthlyReport(specificMonth))
        .thenAnswer((_) async => Right(tReport));

    await useCase(specificMonth);

    verify(() => mockRepo.getMonthlyReport(specificMonth)).called(1);
    verifyNever(() => mockRepo.getMonthlyReport(tMonth));
  });
}
