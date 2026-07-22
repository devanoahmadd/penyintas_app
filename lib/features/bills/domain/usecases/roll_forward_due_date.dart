import 'dart:math' as math;

import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

/// Menghitung tanggal jatuh tempo berikutnya dari [current], secara MURNI
/// (tanpa efek samping, deterministik).
///
/// Anchor hari memakai [dueDayOfMonth] — BUKAN `current.day` — supaya anchor
/// akhir-bulan tidak "hilang". Contoh: anchor 31 yang sempat di-clamp jadi 28
/// (Februari) akan kembali ke 31 di Maret.
///
/// - [Recurrence.monthly]: maju 1 bulan; hari = `min(dueDayOfMonth,
///   hariTerakhirBulanTarget)`.
/// - [Recurrence.yearly]: maju 1 tahun; bulan tetap; hari di-clamp dengan
///   aturan yang sama (mis. 29 Feb kabisat -> 28 Feb non-kabisat).
/// - [Recurrence.none]: tak dipanggil caller normal; ditangani defensif dengan
///   mengembalikan [current] apa adanya.
DateTime rollForwardDueDate({
  required DateTime current,
  required int dueDayOfMonth,
  required Recurrence recurrence,
}) {
  switch (recurrence) {
    case Recurrence.monthly:
      // current.month + 1 = 13 dinormalisasi DateTime menjadi Januari tahun
      // berikutnya, jadi rollover tahun tertangani otomatis.
      final target = DateTime(current.year, current.month + 1, 1);
      return _clampToMonth(target.year, target.month, dueDayOfMonth);
    case Recurrence.yearly:
      return _clampToMonth(current.year + 1, current.month, dueDayOfMonth);
    case Recurrence.none:
      return current;
  }
}

/// Bangun DateTime pada [year]/[month] dengan hari = min(anchor, hari terakhir
/// bulan tersebut). Hari terakhir dihitung via "hari ke-0 bulan berikutnya".
DateTime _clampToMonth(int year, int month, int dueDayOfMonth) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(dueDayOfMonth, lastDay));
}
