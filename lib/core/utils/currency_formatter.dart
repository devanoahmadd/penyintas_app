import 'package:intl/intl.dart';

final _formatter = NumberFormat('#,###', 'id_ID');

/// Format integer Rupiah → "Rp 1.245.000"
/// Locale id_ID menggunakan titik sebagai pemisah ribuan.
String formatRupiah(int amount) {
  return 'Rp ${_formatter.format(amount)}';
}

/// Compact format untuk space sempit → "Rp 1,2jt" / "Rp 480rb"
String formatRupiahCompact(int amount) {
  if (amount >= 1000000) {
    final juta = amount / 1000000;
    final str = juta == juta.truncateToDouble()
        ? juta.toInt().toString()
        : juta.toStringAsFixed(1);
    return 'Rp ${str}jt';
  }
  if (amount >= 1000) {
    final ribu = amount / 1000;
    final str = ribu == ribu.truncateToDouble()
        ? ribu.toInt().toString()
        : ribu.toStringAsFixed(1);
    return 'Rp ${str}rb';
  }
  return formatRupiah(amount);
}
