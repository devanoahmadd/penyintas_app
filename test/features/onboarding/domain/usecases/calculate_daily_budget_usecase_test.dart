import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/daily_budget_result.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/calculate_daily_budget_usecase.dart';

void main() {
  late CalculateDailyBudgetUseCase useCase;
  setUp(() => useCase = CalculateDailyBudgetUseCase());

  group('income tidak valid', () {
    test('income = 0 → Left(ValidationFailure)', () async {
      final result = await useCase(const CalcParams(
        income: 0,
        fixedExpenses: 0,
        emergencyPct: 0.10,
        remainingDays: 30,
      ));
      expect(result, isA<Left>());
      expect((result as Left).value, isA<ValidationFailure>());
    });

    test('income negatif → Left(ValidationFailure)', () async {
      final result = await useCase(const CalcParams(
        income: -1,
        fixedExpenses: 0,
        emergencyPct: 0.10,
        remainingDays: 30,
      ));
      expect(result, isA<Left>());
    });
  });

  group('kalkulasi normal', () {
    test('income > 0 → Right dengan nilai benar', () async {
      final result = await useCase(const CalcParams(
        income: 3000000,
        fixedExpenses: 1200000,
        emergencyPct: 0.10,
        remainingDays: 20,
      ));
      // available=1800000, emergency=180000, spendable=1620000, daily=81000
      expect(result, isA<Right>());
      final v = (result as Right<Failure, DailyBudgetResult>).value;
      expect(v.dailyBudget, 81000);
      expect(v.totalAvailable, 1800000);
      expect(v.emergencyFund, 180000);
    });

    test('fixed >= income → daily = 0, bukan negatif', () async {
      final result = await useCase(const CalcParams(
        income: 1000000,
        fixedExpenses: 1500000,
        emergencyPct: 0.10,
        remainingDays: 20,
      ));
      expect(result, isA<Right>());
      expect((result as Right<Failure, DailyBudgetResult>).value.dailyBudget, 0);
    });

    test('remainingDays = 0 → daily = 0', () async {
      final result = await useCase(const CalcParams(
        income: 3000000,
        fixedExpenses: 0,
        emergencyPct: 0.0,
        remainingDays: 0,
      ));
      expect(result, isA<Right>());
      expect((result as Right<Failure, DailyBudgetResult>).value.dailyBudget, 0);
    });
  });
}
