import 'package:intl/intl.dart';
import 'currency_config.dart';

// Cache NumberFormat per currency code — tidak dibuat ulang setiap panggilan (#135)
final Map<String, NumberFormat> _fmtCache = {};

// Fungsi utama — pakai ini untuk semua nominal mulai Phase 7
String formatCurrency(int amount, CurrencyConfig config) {
  final fmt = _fmtCache.putIfAbsent(
    config.code,
    () => NumberFormat.currency(
      locale: config.locale,
      symbol: '${config.symbol} ',
      decimalDigits: config.decimalDigits,
    ),
  );
  return fmt.format(amount);
}

String formatCurrencyCompact(int amount, CurrencyConfig config) {
  // #134: Guard negatif — tanda minus harus di luar simbol (bukan "Rp -Xrb")
  final isNeg = amount < 0;
  final abs = amount.abs();

  final String result;
  if (abs >= 1000000) {
    final millions = abs / 1000000;
    final val = millions == millions.truncateToDouble()
        ? millions.toStringAsFixed(0)
        : millions.toStringAsFixed(1);
    result = '${config.symbol} $val${config.compactMillion}';
  } else if (abs >= 1000) {
    final val = (abs / 1000).toStringAsFixed(0);
    result = '${config.symbol} $val${config.compactThousand}';
  } else {
    result = formatCurrency(abs, config);
  }

  return isNeg ? '-$result' : result;
}

// Shim — akan dihapus di Phase 8G setelah semua caller diupdate
String formatRupiah(int amount) => formatCurrency(amount, CurrencyConfig.idr);

// Shim compact — akan dihapus di Phase 8G
String formatRupiahCompact(int amount) =>
    formatCurrencyCompact(amount, CurrencyConfig.idr);
