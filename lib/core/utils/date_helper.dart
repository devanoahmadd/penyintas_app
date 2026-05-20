import 'package:intl/intl.dart';

/// Hari tersisa hingga tanggal kiriman berikutnya.
/// Jika hari ini = paymentDate, kembalikan 0 (kiriman hari ini).
int remainingDaysInCycle(int paymentDate) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime nextPayment;
  if (today.day < paymentDate) {
    nextPayment = _clampedDate(today.year, today.month, paymentDate);
  } else {
    // Bulan depan — handle overflow (mis. tanggal 31 di bulan 30 hari)
    final nextMonth = today.month == 12 ? 1 : today.month + 1;
    final nextYear = today.month == 12 ? today.year + 1 : today.year;
    nextPayment = _clampedDate(nextYear, nextMonth, paymentDate);
  }

  return nextPayment.difference(today).inDays;
}

/// Buat DateTime dengan tanggal yang di-clamp ke hari terakhir bulan tersebut.
DateTime _clampedDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, lastDay));
}

/// "12 Jan", "3 Des" — format pendek untuk list
String formatDateShort(DateTime date) =>
    DateFormat('d MMM', 'id_ID').format(date);

/// "Senin, 12 Januari 2025" — format panjang untuk header grup
String formatDateLong(DateTime date) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

/// Menghitung total hari dalam siklus pembayaran penuh berikutnya.
/// Digunakan sebagai fallback saat remainingDays == 0 (hari kiriman).
int daysInCycle(int paymentDate) {
  final now = DateTime.now();
  final start = _clampedDate(now.year, now.month, paymentDate);
  final nextMonth = now.month == 12 ? 1 : now.month + 1;
  final nextYear = now.month == 12 ? now.year + 1 : now.year;
  final end = _clampedDate(nextYear, nextMonth, paymentDate);
  return end.difference(start).inDays;
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
