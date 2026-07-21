import 'package:intl/intl.dart';

// ── Private helpers ───────────────────────────────────────────────────────────

/// Buat DateTime midnight yang di-clamp ke hari terakhir bulan tersebut.
DateTime _clampedDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, lastDay));
}

/// Tanggal pembayaran berikutnya relatif terhadap [today] (midnight).
/// Digunakan bersama oleh [remainingDaysInCycle] dan [cycleEnd] — fix #7.
DateTime _nextPaymentDate(DateTime today, int paymentDate) {
  if (today.day < paymentDate) {
    return _clampedDate(today.year, today.month, paymentDate);
  } else {
    final nextMonth = today.month == 12 ? 1 : today.month + 1;
    final nextYear = today.month == 12 ? today.year + 1 : today.year;
    return _clampedDate(nextYear, nextMonth, paymentDate);
  }
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Hari tersisa hingga tanggal kiriman berikutnya.
/// Jika hari ini = paymentDate, kembalikan 0 (kiriman hari ini).
///
/// Parameter [now] opsional — lihat [cycleStart] untuk penjelasan (#4).
int remainingDaysInCycle(int paymentDate, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  return _nextPaymentDate(today, paymentDate).difference(today).inDays;
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
  final today = DateTime(now.year, now.month, now.day);
  final start = _clampedDate(today.year, today.month, paymentDate);
  // Tidak pakai _nextPaymentDate(start) karena bila paymentDate > lastDayOfMonth,
  // start sudah di-clamp ke lastDay dan start.day < paymentDate masih true →
  // _nextPaymentDate mengembalikan start lagi → selisih = 0.
  final nextMonth = start.month == 12 ? 1 : start.month + 1;
  final nextYear = start.month == 12 ? start.year + 1 : start.year;
  final end = _clampedDate(nextYear, nextMonth, paymentDate);
  return end.difference(start).inDays;
}

/// Awal siklus pembayaran yang sedang berjalan.
/// - today.day >= paymentDate → tanggal [paymentDate] bulan ini
/// - today.day < paymentDate → tanggal [paymentDate] bulan lalu
///
/// Parameter [now] opsional — gunakan satu instance `DateTime.now()` yang sama
/// untuk semua pemanggilan date-helper dalam satu komputasi agar tidak ada
/// perbedaan "hari" akibat eksekusi melintas tengah malam (#4).
DateTime cycleStart(int paymentDate, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  if (today.day >= paymentDate) {
    return _clampedDate(today.year, today.month, paymentDate);
  } else {
    final prevMonth = today.month == 1 ? 12 : today.month - 1;
    final prevYear = today.month == 1 ? today.year - 1 : today.year;
    return _clampedDate(prevYear, prevMonth, paymentDate);
  }
}

/// Akhir siklus pembayaran yang sedang berjalan — 23:59:59 pada hari terakhir
/// siklus (sehari sebelum tanggal pembayaran berikutnya).
///
/// Guard: jika [paymentDate] > hari terakhir bulan berikutnya (mis. paymentDate=30
/// di Februari), _clampedDate menggeser [nextPayment] ke belakang, sehingga
/// `nextPayment - 1 hari` bisa jatuh sebelum hari ini. Guard ini memastikan
/// siklus selalu mencakup setidaknya hingga akhir hari ini.
///
/// Parameter [now] opsional — lihat [cycleStart] untuk penjelasan (#4).
DateTime cycleEnd(int paymentDate, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final nextPayment = _nextPaymentDate(today, paymentDate);
  // Hari terakhir siklus = sehari sebelum pembayaran berikutnya.
  // Guard: bila clamp menggeser nextPayment ke hari ini atau sebelumnya,
  // gunakan hari ini agar transaksi hari ini selalu masuk dalam window.
  final lastDay = nextPayment.subtract(const Duration(days: 1));
  final effectiveLastDay = lastDay.isBefore(today) ? today : lastDay;
  return DateTime(
    effectiveLastDay.year,
    effectiveLastDay.month,
    effectiveLastDay.day,
    23,
    59,
    59,
    999,
  );
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
