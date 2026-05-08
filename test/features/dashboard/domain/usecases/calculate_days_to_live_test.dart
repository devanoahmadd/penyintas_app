import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/calculate_days_to_live_usecase.dart';

void main() {
  const useCase = CalculateDaysToLiveUseCase();

  group('CalculateDaysToLiveUseCase', () {
    test('avgDailySpend <= 0 → returns remainingDays', () {
      final result = useCase(const CalcDtlParams(
        totalRemaining: 500000,
        avgDailySpend: 0,
        remainingDays: 15,
      ));
      expect(result, 15);
    });

    test('normal case → floor(totalRemaining / avgDailySpend)', () {
      final result = useCase(const CalcDtlParams(
        totalRemaining: 300000,
        avgDailySpend: 50000,
        remainingDays: 20,
      ));
      expect(result, 6);
    });

    test('totalRemaining negative → returns 0', () {
      final result = useCase(const CalcDtlParams(
        totalRemaining: -100000,
        avgDailySpend: 50000,
        remainingDays: 10,
      ));
      expect(result, 0);
    });

    test('totalRemaining zero → returns 0', () {
      final result = useCase(const CalcDtlParams(
        totalRemaining: 0,
        avgDailySpend: 50000,
        remainingDays: 10,
      ));
      expect(result, 0);
    });

    test('result floors (not rounds)', () {
      // 150000 / 70000 = 2.14... → floor = 2
      final result = useCase(const CalcDtlParams(
        totalRemaining: 150000,
        avgDailySpend: 70000,
        remainingDays: 10,
      ));
      expect(result, 2);
    });
  });
}
