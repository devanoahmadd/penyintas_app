import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';

void main() {
  group('localDayKey', () {
    test('memampatkan tanggal lokal jadi yyyymmdd', () {
      expect(localDayKey(DateTime(2026, 9, 2, 23, 59)), 20260902);
      expect(localDayKey(DateTime(2026, 1, 5, 0, 0)), 20260105);
    });
  });

  group('localMidnightOf', () {
    test('mengembalikan tengah malam lokal hari itu', () {
      expect(localMidnightOf(20260902), DateTime(2026, 9, 2));
    });

    test('bolak-balik dengan localDayKey tanpa kehilangan hari', () {
      for (final key in [20260101, 20260228, 20261231]) {
        expect(localDayKey(localMidnightOf(key)), key);
      }
    });
  });

  group('addDays', () {
    test('melewati pergantian bulan', () {
      expect(addDays(20260930, 1), 20261001);
      expect(addDays(20260902, 2), 20260904);
    });

    test('melewati pergantian tahun dan tahun kabisat', () {
      expect(addDays(20261231, 1), 20270101);
      expect(addDays(20280228, 1), 20280229); // 2028 kabisat
    });

    test('menerima nilai negatif', () {
      expect(addDays(20260301, -1), 20260228);
    });
  });

  group('FixedClock', () {
    test('mengembalikan waktu yang disetel, dan bisa digeser', () {
      final clock = FixedClock(DateTime(2026, 9, 2, 10));
      expect(localDayKey(clock.now()), 20260902);
      clock.at = DateTime(2026, 9, 5, 10);
      expect(localDayKey(clock.now()), 20260905);
    });
  });
}
