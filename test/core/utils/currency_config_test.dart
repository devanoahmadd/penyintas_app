import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/currency_config.dart';

void main() {
  group('CurrencyConfig', () {
    test('IDR config values are correct', () {
      const idr = CurrencyConfig.idr;
      expect(idr.code, 'IDR');
      expect(idr.symbol, 'Rp');
      expect(idr.locale, 'id_ID');
      expect(idr.decimalDigits, 0);
      expect(idr.compactThousand, 'rb');
      expect(idr.compactMillion, 'jt');
    });

    test('fromCode returns IDR for "IDR"', () {
      expect(CurrencyConfig.fromCode('IDR'), CurrencyConfig.idr);
    });

    test('fromCode falls back to IDR for unknown code', () {
      expect(CurrencyConfig.fromCode('USD'), CurrencyConfig.idr);
      expect(CurrencyConfig.fromCode(''), CurrencyConfig.idr);
    });

    test('fromCode is case-insensitive', () {
      expect(CurrencyConfig.fromCode('idr'), CurrencyConfig.idr);
      expect(CurrencyConfig.fromCode('Idr'), CurrencyConfig.idr);
      expect(CurrencyConfig.fromCode('IDR'), CurrencyConfig.idr);
    });

    test('registry contains IDR', () {
      expect(CurrencyConfig.registry.containsKey('IDR'), isTrue);
    });

    test('equality: two identical configs are equal', () {
      const a = CurrencyConfig.idr;
      const b = CurrencyConfig.idr;
      expect(a, equals(b));
    });
  });
}
