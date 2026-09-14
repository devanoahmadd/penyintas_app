import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';

// 2026-09-07 adalah Senin; 2026-09-13 adalah Minggu di minggu yang sama.
DateTime _senin([int jam = 9]) => DateTime(2026, 9, 7, jam);
DateTime _selasa() => DateTime(2026, 9, 8, 9);
DateTime _rabu() => DateTime(2026, 9, 9, 9);
DateTime _jumat() => DateTime(2026, 9, 11, 9);
DateTime _minggu() => DateTime(2026, 9, 13, 23, 59);

void main() {
  group('weekKeyOf', () {
    test('U20 · Minggu 2026-09-13 → 20260907 (Senin minggu itu)', () {
      expect(weekKeyOf(_minggu()), 20260907);
    });

    test('U20 · Senin sendiri → dirinya', () {
      expect(weekKeyOf(_senin()), 20260907);
    });

    test('U20 · jam tidak memengaruhi hasil', () {
      expect(weekKeyOf(_senin(0)), weekKeyOf(_senin(23)));
    });

    test('U20 · minggu berikutnya menghasilkan weekKey berbeda', () {
      expect(weekKeyOf(DateTime(2026, 9, 14, 9)), 20260914);
    });

    test('U20 · lintas bulan: Selasa 2026-09-01 → Senin 2026-08-31', () {
      expect(weekKeyOf(DateTime(2026, 9, 1, 9)), 20260831);
    });
  });

  group('isCreationWindow', () {
    test('U19 · Senin dan Selasa terbuka', () {
      expect(isCreationWindow(_senin()), isTrue);
      expect(isCreationWindow(_selasa()), isTrue);
    });

    test('U19 · Rabu sampai Minggu tertutup', () {
      expect(isCreationWindow(_rabu()), isFalse);
      expect(isCreationWindow(_jumat()), isFalse);
      expect(isCreationWindow(_minggu()), isFalse);
    });
  });

  group('daysLeftInWeek', () {
    test('U21 · Senin → 7, Jumat → 3, Minggu → 1 (termasuk hari ini)', () {
      expect(daysLeftInWeek(_senin()), 7);
      expect(daysLeftInWeek(_jumat()), 3);
      expect(daysLeftInWeek(_minggu()), 1);
    });

    test('U21 · tidak pernah nol atau negatif', () {
      for (var h = 7; h <= 13; h++) {
        expect(daysLeftInWeek(DateTime(2026, 9, h, 12)), greaterThan(0));
      }
    });
  });

  group('evaluateResult', () {
    test('U18 · finalSpent == target → achieved (batas INKLUSIF)', () {
      expect(evaluateResult(target: 115000, finalSpent: 115000),
          ChallengeStatus.achieved);
    });

    test('U18 · di bawah target → achieved', () {
      expect(evaluateResult(target: 115000, finalSpent: 113500),
          ChallengeStatus.achieved);
    });

    test('U18 · di atas target → missed', () {
      expect(evaluateResult(target: 115000, finalSpent: 115001),
          ChallengeStatus.missed);
    });
  });
}
