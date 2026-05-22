import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/currency_config.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';

void main() {
  const idr = CurrencyConfig.idr;

  group('formatCurrency', () {
    test('formats 1.245.000 correctly', () {
      expect(formatCurrency(1245000, idr), 'Rp 1.245.000');
    });

    test('formats zero', () {
      expect(formatCurrency(0, idr), 'Rp 0');
    });

    test('formats small amount under 1000', () {
      expect(formatCurrency(500, idr), 'Rp 500');
    });

    test('formats exactly 1000', () {
      expect(formatCurrency(1000, idr), 'Rp 1.000');
    });

    test('formats 480000 correctly', () {
      expect(formatCurrency(480000, idr), 'Rp 480.000');
    });
  });

  group('formatCurrencyCompact', () {
    test('formats millions with jt suffix', () {
      expect(formatCurrencyCompact(1200000, idr), 'Rp 1.2jt');
    });

    test('formats exact million as integer suffix', () {
      expect(formatCurrencyCompact(2000000, idr), 'Rp 2jt');
    });

    test('formats thousands with rb suffix', () {
      expect(formatCurrencyCompact(480000, idr), 'Rp 480rb');
    });

    test('formats amount below 1000 as full currency', () {
      expect(formatCurrencyCompact(500, idr), 'Rp 500');
    });
  });

  group('negative amounts', () {
    test('formatCurrency delegates negative to NumberFormat', () {
      expect(formatCurrency(-25000, idr), isA<String>());
    });

    test('formatCurrencyCompact negative thousands: minus outside symbol', () {
      expect(formatCurrencyCompact(-25000, idr), '-Rp 25rb');
    });

    test('formatCurrencyCompact negative millions: minus outside symbol', () {
      expect(formatCurrencyCompact(-2000000, idr), '-Rp 2jt');
    });

    test('formatCurrencyCompact negative below 1000: minus outside symbol', () {
      expect(formatCurrencyCompact(-500, idr), startsWith('-Rp'));
    });
  });

  group('shims', () {
    test('formatRupiah delegates to formatCurrency IDR', () {
      expect(formatRupiah(1245000), formatCurrency(1245000, idr));
    });

    test('formatRupiahCompact delegates to formatCurrencyCompact IDR', () {
      expect(formatRupiahCompact(1200000), formatCurrencyCompact(1200000, idr));
    });
  });
}
