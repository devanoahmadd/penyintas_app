import 'dart:math' as math;

/// Bangun [DateTime] pada [year]/[month] dengan hari = `min(dayAnchor, hari
/// terakhir bulan tersebut)`. Hari terakhir dihitung via "hari ke-0 bulan
/// berikutnya" (trik `DateTime(year, month + 1, 0)`).
///
/// Dipakai bersama oleh `rollForwardDueDate` dan `nextPayday` supaya logika
/// clamp akhir-bulan (mis. anchor 31 di Februari -> 28/29) tidak terduplikasi.
DateTime clampDayOfMonth(int year, int month, int dayAnchor) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(dayAnchor, lastDay));
}
