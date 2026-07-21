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
      final result = await useCase(
        const CalcParams(
          income: 0,
          fixedExpenses: 0,
          emergencyPct: 0.10,
          remainingDays: 30,
        ),
      );
      expect(result, isA<Left>());
      expect((result as Left).value, isA<ValidationFailure>());
    });

    test('income negatif → Left(ValidationFailure)', () async {
      final result = await useCase(
        const CalcParams(
          income: -1,
          fixedExpenses: 0,
          emergencyPct: 0.10,
          remainingDays: 30,
        ),
      );
      expect(result, isA<Left>());
      expect((result as Left).value, isA<ValidationFailure>());
    });
  });

  group('kalkulasi normal', () {
    test('income > 0 → Right dengan nilai benar', () async {
      final result = await useCase(
        const CalcParams(
          income: 3000000,
          fixedExpenses: 1200000,
          emergencyPct: 0.10,
          remainingDays: 20,
        ),
      );
      // available=1800000, emergency=180000, spendable=1620000, daily=81000
      expect(result, isA<Right>());
      final v = (result as Right<Failure, DailyBudgetResult>).value;
      expect(v.dailyBudget, 81000);
      expect(v.totalAvailable, 1800000);
      expect(v.emergencyFund, 180000);
    });

    test('fixed >= income → daily = 0, bukan negatif', () async {
      final result = await useCase(
        const CalcParams(
          income: 1000000,
          fixedExpenses: 1500000,
          emergencyPct: 0.10,
          remainingDays: 20,
        ),
      );
      expect(result, isA<Right>());
      expect(
        (result as Right<Failure, DailyBudgetResult>).value.dailyBudget,
        0,
      );
    });

    test('remainingDays = 0 → daily = 0', () async {
      final result = await useCase(
        const CalcParams(
          income: 3000000,
          fixedExpenses: 0,
          emergencyPct: 0.0,
          remainingDays: 0,
        ),
      );
      expect(result, isA<Right>());
      expect(
        (result as Right<Failure, DailyBudgetResult>).value.dailyBudget,
        0,
      );
    });

    test('remainingDays = 1 → daily = spendable penuh', () async {
      final result = await useCase(
        const CalcParams(
          income: 1500000,
          fixedExpenses: 500000,
          emergencyPct: 0.10,
          remainingDays: 1,
        ),
      );
      // available=1000000, emergency=100000, spendable=900000, daily=900000
      expect(result, isA<Right>());
      expect(
        (result as Right<Failure, DailyBudgetResult>).value.dailyBudget,
        900000,
      );
    });

    test('daily di-floor, bukan dibulatkan ke atas', () async {
      final result = await useCase(
        const CalcParams(
          income: 1000000,
          fixedExpenses: 0,
          emergencyPct: 0.0,
          remainingDays: 3,
        ),
      );
      // spendable=1000000, daily=333333.33 → floor 333333
      expect(result, isA<Right>());
      expect(
        (result as Right<Failure, DailyBudgetResult>).value.dailyBudget,
        333333,
      );
    });

    test('emergency maksimum 25%', () async {
      final result = await useCase(
        const CalcParams(
          income: 2000000,
          fixedExpenses: 0,
          emergencyPct: 0.25,
          remainingDays: 25,
        ),
      );
      // emergency=500000, spendable=1500000, daily=60000
      expect(result, isA<Right>());
      final v = (result as Right<Failure, DailyBudgetResult>).value;
      expect(v.emergencyFund, 500000);
      expect(v.dailyBudget, 60000);
    });
  });

  group('CalcParams equality', () {
    test('dua instance nilai sama → equal (Equatable)', () {
      final a = CalcParams(
        income: 1500000,
        fixedExpenses: 600000,
        emergencyPct: 0.10,
        remainingDays: 30,
      );
      final b = CalcParams(
        income: 1500000,
        fixedExpenses: 600000,
        emergencyPct: 0.10,
        remainingDays: 30,
      );
      expect(a, equals(b));
    });
  });
}
