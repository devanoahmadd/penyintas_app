import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('hash tidak sama dengan PIN mentah', () {
      final salt = PinHasher.generateSalt();
      final h = PinHasher.hash('123456', salt);
      expect(h, isNot(contains('123456')));
      expect(h.isNotEmpty, isTrue);
    });

    test('verify true untuk PIN + salt yang benar', () {
      final salt = PinHasher.generateSalt();
      final h = PinHasher.hash('123456', salt);
      expect(PinHasher.verify('123456', salt, h), isTrue);
    });

    test('verify false untuk PIN salah', () {
      final salt = PinHasher.generateSalt();
      final h = PinHasher.hash('123456', salt);
      expect(PinHasher.verify('000000', salt, h), isFalse);
    });

    test('salt berbeda menghasilkan hash berbeda untuk PIN sama', () {
      final s1 = PinHasher.generateSalt(Random(1));
      final s2 = PinHasher.generateSalt(Random(2));
      expect(PinHasher.hash('123456', s1),
          isNot(PinHasher.hash('123456', s2)));
    });

    test('deterministik: PIN+salt sama → hash sama', () {
      final salt = PinHasher.generateSalt(Random(1));
      expect(PinHasher.hash('123456', salt), PinHasher.hash('123456', salt));
    });
  });
}
