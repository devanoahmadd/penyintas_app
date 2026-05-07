import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/calculate_daily_budget_usecase.dart';

void main() {
  late CalculateDailyBudgetUseCase useCase;

  setUp(() {
    useCase = CalculateDailyBudgetUseCase();
  });

  group('CalculateDailyBudgetUseCase', () {
    test('should return correct daily budget for normal inputs', () async {
      // income 1.500.000, fixed 600.000, emergency 10%, 30 days
      final result = await useCase(const CalcParams(
        income: 1500000,
        fixedExpenses: 600000,
        emergencyPct: 0.10,
        remainingDays: 30,
      ));

      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (r) {
          // available = 900.000, emergency = 90.000, spendable = 810.000
          // daily = 810.000 / 30 = 27.000
          expect(r.totalAvailable, 900000);
          expect(r.emergencyFund, 90000);
          expect(r.dailyBudget, 27000);
          expect(r.remainingDays, 30);
        },
      );
    });

    test('should return zero emergency fund when emergencyPct is 0', () async {
      final result = await useCase(const CalcParams(
        income: 1000000,
        fixedExpenses: 200000,
        emergencyPct: 0.0,
        remainingDays: 20,
      ));

      result.fold(
        (failure) => fail('Expected Right'),
        (r) {
          expect(r.emergencyFund, 0);
          // spendable = 800.000, daily = 800.000 / 20 = 40.000
          expect(r.dailyBudget, 40000);
        },
      );
    });

    test('should return zero daily budget when remainingDays is 0', () async {
      final result = await useCase(const CalcParams(
        income: 1500000,
        fixedExpenses: 500000,
        emergencyPct: 0.10,
        remainingDays: 0,
      ));

      result.fold(
        (failure) => fail('Expected Right'),
        (r) => expect(r.dailyBudget, 0),
      );
    });

    test('should return zero daily budget when remainingDays is 1', () async {
      final result = await useCase(const CalcParams(
        income: 1500000,
        fixedExpenses: 500000,
        emergencyPct: 0.10,
        remainingDays: 1,
      ));

      result.fold(
        (failure) => fail('Expected Right'),
        (r) {
          // available = 1.000.000, emergency = 100.000, spendable = 900.000
          // daily = 900.000 / 1 = 900.000
          expect(r.dailyBudget, 900000);
        },
      );
    });

    test('should clamp to zero when fixedExpenses exceeds income', () async {
      final result = await useCase(const CalcParams(
        income: 500000,
        fixedExpenses: 700000,
        emergencyPct: 0.10,
        remainingDays: 15,
      ));

      result.fold(
        (failure) => fail('Expected Right'),
        (r) {
          expect(r.totalAvailable, 0);
          expect(r.emergencyFund, 0);
          expect(r.dailyBudget, 0);
        },
      );
    });

    test('should floor daily budget — not round up', () async {
      // income 1.000.000, fixed 0, emergency 0, remaining 3
      // spendable = 1.000.000, daily = 333.333.33... → floor = 333.333
      final result = await useCase(const CalcParams(
        income: 1000000,
        fixedExpenses: 0,
        emergencyPct: 0.0,
        remainingDays: 3,
      ));

      result.fold(
        (failure) => fail('Expected Right'),
        (r) => expect(r.dailyBudget, 333333),
      );
    });

    test('should handle maximum emergency fund (25%)', () async {
      final result = await useCase(const CalcParams(
        income: 2000000,
        fixedExpenses: 0,
        emergencyPct: 0.25,
        remainingDays: 25,
      ));

      result.fold(
        (failure) => fail('Expected Right'),
        (r) {
          expect(r.emergencyFund, 500000);
          // spendable = 1.500.000, daily = 1.500.000 / 25 = 60.000
          expect(r.dailyBudget, 60000);
        },
      );
    });
  });

  group('CalcParams equality', () {
    test('two instances with same values should be equal', () {
      // tanpa const agar Dart buat dua object terpisah — memaksa Equatable akses props
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
