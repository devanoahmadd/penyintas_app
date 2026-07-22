import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/bills/domain/usecases/next_payday.dart';

void main() {
  group('nextPayday', () {
    test('10 Jul, paymentDate=25 -> 25 Jul (masih akan datang)', () {
      expect(
        nextPayday(today: DateTime(2027, 7, 10), paymentDate: 25),
        DateTime(2027, 7, 25),
      );
    });

    test('25 Jul, paymentDate=25 -> 25 Aug (sama-hari, maju bulan depan)', () {
      // KUNCI anti-sabotase: kondisi maju harus `<= today`, BUKAN `< today`.
      // Bila candidate == today, gajian hari ini dianggap sudah lewat/cair,
      // horizon berikutnya harus maju ke bulan depan.
      expect(
        nextPayday(today: DateTime(2027, 7, 25), paymentDate: 25),
        DateTime(2027, 8, 25),
      );
    });

    test('10 Feb 2027, paymentDate=31 -> 28 Feb 2027 (clamp akhir-bulan)', () {
      expect(
        nextPayday(today: DateTime(2027, 2, 10), paymentDate: 31),
        DateTime(2027, 2, 28),
      );
    });
  });
}
