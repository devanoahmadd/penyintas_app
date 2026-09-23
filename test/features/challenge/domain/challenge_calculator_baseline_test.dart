import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/weekly_spend.dart';

// Empat minggu penuh sebelum minggu berjalan 20260914:
// 20260810, 20260817, 20260824, 20260831, lalu 20260907 = minggu terakhir penuh.
// Minggu berjalan = 20260914.
const _mingguIni = 20260914;

void main() {
  group('computeBaselines', () {
    test('U1 · 4 minggu berdata → basis = rata-rata 4', () {
      final hasil = computeBaselines(
        spends: const [
          WeeklySpend(weekKey: 20260817, category: 'food', amount: 100000),
          WeeklySpend(weekKey: 20260824, category: 'food', amount: 120000),
          WeeklySpend(weekKey: 20260831, category: 'food', amount: 140000),
          WeeklySpend(weekKey: 20260907, category: 'food', amount: 160000),
        ],
        currentWeekKey: _mingguIni,
      );
      expect(hasil.baselines['food'], 130000); // 520000 / 4
      expect(hasil.weeksWithData['food'], 4);
    });

    test('U2 · 2 dari 4 minggu berdata → pembagi 2, BUKAN 4', () {
      final hasil = computeBaselines(
        spends: const [
          WeeklySpend(weekKey: 20260831, category: 'food', amount: 100000),
          WeeklySpend(weekKey: 20260907, category: 'food', amount: 140000),
        ],
        currentWeekKey: _mingguIni,
      );
      // Pembagi 4 akan memberi 60000 — target 15% di bawahnya mustahil sejak
      // hari pertama, dan bertolak belakang dengan copy "Catat dulu dua minggu".
      expect(hasil.baselines['food'], 120000);
      expect(hasil.weeksWithData['food'], 2);
    });

    test('U3 · minggu berjalan TIDAK ikut basis', () {
      final hasil = computeBaselines(
        spends: const [
          WeeklySpend(weekKey: 20260907, category: 'food', amount: 100000),
          WeeklySpend(weekKey: _mingguIni, category: 'food', amount: 900000),
        ],
        currentWeekKey: _mingguIni,
      );
      expect(hasil.baselines['food'], 100000);
      expect(hasil.weeksWithData['food'], 1);
    });

    test('U1 · minggu lebih tua dari 4 minggu terakhir diabaikan', () {
      final hasil = computeBaselines(
        spends: const [
          WeeklySpend(weekKey: 20260713, category: 'food', amount: 900000),
          WeeklySpend(weekKey: 20260907, category: 'food', amount: 100000),
        ],
        currentWeekKey: _mingguIni,
      );
      expect(hasil.baselines['food'], 100000);
    });

    test('U9 · daftar kosong → map kosong, bukan exception', () {
      final hasil = computeBaselines(
        spends: const [],
        currentWeekKey: _mingguIni,
      );
      expect(hasil.baselines, isEmpty);
      expect(hasil.weeksWithData, isEmpty);
    });
  });

  group('computeTarget', () {
    test('U11 · basis 140.000 → 115.000, dibulatkan KE BAWAH', () {
      // 140000 × 0,85 = 119.000 → 119000 / 5000 = 23,8 → floor 23 → 115.000.
      // Pembulatannya TERLIHAT bekerja di sini (119 → 115), bukan kebetulan.
      expect(computeTarget(140000), 115000);
      // Basis 141.000 mendarat di angka yang sama — inilah yang membuat contoh
      // "141.000 → 120.000" di spec §2 T4 keliru: 119.850 floor 5.000 = 115.000.
      expect(computeTarget(141000), 115000);
    });

    test('U12 · basis 100.000 → 85.000 tepat kelipatan', () {
      expect(computeTarget(100000), 85000);
    });

    test('U11 · pembulatan selalu ke bawah, tidak pernah ke terdekat', () {
      // 130000 × 0,85 = 110.500 → floor kelipatan 5.000 = 110.000.
      expect(computeTarget(130000), 110000);
    });

    test('basis 0 → target 0, tanpa exception', () {
      expect(computeTarget(0), 0);
    });
  });
}
