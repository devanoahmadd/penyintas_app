import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';

void main() {
  PartialOnboardingState withSavedAt(DateTime savedAt) => PartialOnboardingState(
        step: 0,
        income: 1000000,
        expenses: const {'kos': 0, 'listrik': 0, 'internet': 0, 'pulsa': 0, 'lain': 0},
        pct: 10,
        payday: 1,
        savedAt: savedAt,
      );

  group('isExpired (#232)', () {
    final now = DateTime(2026, 6, 11, 12);

    test('6 hari → belum kedaluwarsa', () {
      final s = withSavedAt(now.subtract(const Duration(days: 6)));
      expect(s.isExpired(now: now), false);
    });

    test('7 hari → kedaluwarsa (batas)', () {
      final s = withSavedAt(now.subtract(const Duration(days: 7)));
      expect(s.isExpired(now: now), true);
    });

    test('8 hari → kedaluwarsa', () {
      final s = withSavedAt(now.subtract(const Duration(days: 8)));
      expect(s.isExpired(now: now), true);
    });

    test('staleDays = 7', () {
      expect(PartialOnboardingState.staleDays, 7);
    });
  });
}
