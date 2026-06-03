import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/report/data/datasources/report_local_datasource.dart';
import 'package:penyintas_app/features/report/data/datasources/report_remote_datasource.dart';
import 'package:penyintas_app/features/report/data/repositories/report_repository_impl.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class MockReportLocalDatasource extends Mock implements ReportLocalDatasource {}

class MockReportRemoteDatasource extends Mock implements ReportRemoteDatasource {}

void main() {
  late ReportRepositoryImpl repo;
  late MockReportLocalDatasource mockLocal;
  late MockReportRemoteDatasource mockRemote;
  late AppDatabase testDb;

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
      WeeklySpendEntity(weekNumber: 1, totalSpent: 200000),
      WeeklySpendEntity(weekNumber: 2, totalSpent: 150000),
      WeeklySpendEntity(weekNumber: 3, totalSpent: 100000),
      WeeklySpendEntity(weekNumber: 4, totalSpent: 50000),
      WeeklySpendEntity(weekNumber: 5, totalSpent: 0),
    ],
    comparedToPreviousMonth: 0.0,
  );

  setUp(() {
    mockLocal = MockReportLocalDatasource();
    mockRemote = MockReportRemoteDatasource();
    testDb = AppDatabase(NativeDatabase.memory());
    repo = ReportRepositoryImpl(
      local: mockLocal,
      remote: mockRemote,
      db: testDb,
    );
  });

  tearDown(() async => testDb.close());

  group('getMonthlyReport', () {
    test('returns Right(report) from local datasource on success', () async {
      when(() => mockLocal.getMonthlyReport(tMonth))
          .thenAnswer((_) async => tReport);

      final result = await repo.getMonthlyReport(tMonth);

      expect(result, Right<Failure, ReportEntity>(tReport));
    });

    test('returns Left(CacheFailure) when local datasource throws', () async {
      when(() => mockLocal.getMonthlyReport(tMonth))
          .thenThrow(Exception('db error'));

      final result = await repo.getMonthlyReport(tMonth);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getAiInsights', () {
    test('returns Right((insights, savingTip)) from remote datasource on success',
        () async {
      await testDb.into(testDb.appSettings).insert(
            AppSettingsCompanion.insert(id: const Value(1)),
          );

      when(() => mockRemote.getAiInsights(
            reportData: any(named: 'reportData'),
            settingsData: any(named: 'settingsData'),
          )).thenAnswer(
        (_) async => (['insight1', 'insight2', 'insight3'], 'Tip hemat bulan ini.'),
      );

      final result = await repo.getAiInsights(tReport);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (tuple) {
          expect(tuple.$1, ['insight1', 'insight2', 'insight3']);
          expect(tuple.$2, 'Tip hemat bulan ini.');
        },
      );
    });

    test('returns Left(ServerFailure) when remote datasource throws', () async {
      await testDb.into(testDb.appSettings).insert(
            AppSettingsCompanion.insert(id: const Value(1)),
          );

      when(() => mockRemote.getAiInsights(
            reportData: any(named: 'reportData'),
            settingsData: any(named: 'settingsData'),
          )).thenThrow(Exception('network error'));

      final result = await repo.getAiInsights(tReport);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
