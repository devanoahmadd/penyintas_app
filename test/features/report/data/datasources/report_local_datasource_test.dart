import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/report/data/datasources/report_local_datasource.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

void main() {
  late AppDatabase db;
  late ReportLocalDatasourceImpl datasource;

  final tMonth = DateTime(2025, 11);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    datasource = ReportLocalDatasourceImpl(db);
  });

  tearDown(() async => db.close());

  Future<void> insertTx({
    required String id,
    required int amount,
    required TransactionType type,
    required String category,
    required DateTime date,
  }) async {
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          txId: id,
          amount: amount,
          category: category,
          type: type.name,
          date: date,
          createdAt: date,
          updatedAt: date,
        ));
  }

  test('totalSpent equals sum of all expense transactions', () async {
    await insertTx(
      id: '1',
      amount: 50000,
      type: TransactionType.expense,
      category: 'food',
      date: DateTime(2025, 11, 5),
    );
    await insertTx(
      id: '2',
      amount: 30000,
      type: TransactionType.expense,
      category: 'transport',
      date: DateTime(2025, 11, 10),
    );

    final report = await datasource.getMonthlyReport(tMonth);

    expect(report.totalSpent, 80000);
  });

  test('totalIncome equals sum of all income transactions', () async {
    await insertTx(
      id: '1',
      amount: 1000000,
      type: TransactionType.income,
      category: 'income',
      date: DateTime(2025, 11, 1),
    );

    final report = await datasource.getMonthlyReport(tMonth);

    expect(report.totalIncome, 1000000);
  });

  test('categoryBreakdown distributes expenses correctly', () async {
    await insertTx(
      id: '1',
      amount: 100000,
      type: TransactionType.expense,
      category: 'food',
      date: DateTime(2025, 11, 5),
    );
    await insertTx(
      id: '2',
      amount: 50000,
      type: TransactionType.expense,
      category: 'transport',
      date: DateTime(2025, 11, 6),
    );
    await insertTx(
      id: '3',
      amount: 40000,
      type: TransactionType.expense,
      category: 'food',
      date: DateTime(2025, 11, 7),
    );

    final report = await datasource.getMonthlyReport(tMonth);

    expect(report.categoryBreakdown['food'], 140000);
    expect(report.categoryBreakdown['transport'], 50000);
  });

  test('empty month returns all zeros and null topCategory', () async {
    final report = await datasource.getMonthlyReport(tMonth);

    expect(report.totalSpent, 0);
    expect(report.totalIncome, 0);
    expect(report.netBalance, 0);
    expect(report.topCategory, isNull);
    expect(report.categoryBreakdown, isEmpty);
  });

  test('comparedToPreviousMonth is 0.0 when no previous month data', () async {
    await insertTx(
      id: '1',
      amount: 200000,
      type: TransactionType.expense,
      category: 'food',
      date: DateTime(2025, 11, 10),
    );

    final report = await datasource.getMonthlyReport(tMonth);

    expect(report.comparedToPreviousMonth, 0.0);
  });

  test('weeklyBreakdown has 5 elements with correct sums', () async {
    await insertTx(
      id: '1',
      amount: 50000,
      type: TransactionType.expense,
      category: 'food',
      date: DateTime(2025, 11, 3), // week 1
    );
    await insertTx(
      id: '2',
      amount: 30000,
      type: TransactionType.expense,
      category: 'transport',
      date: DateTime(2025, 11, 10), // week 2
    );

    final report = await datasource.getMonthlyReport(tMonth);

    expect(report.weeklyBreakdown.length, 5);
    expect(report.weeklyBreakdown[0].weekNumber, 1);
    expect(report.weeklyBreakdown[0].totalSpent, 50000);
    expect(report.weeklyBreakdown[1].weekNumber, 2);
    expect(report.weeklyBreakdown[1].totalSpent, 30000);
    expect(report.weeklyBreakdown[2].totalSpent, 0);
  });
}
