import 'package:penyintas_app/features/bills/domain/usecases/clamp_day_of_month.dart';

/// Menghitung tanggal gajian berikutnya dari [today], secara MURNI (tanpa
/// efek samping, deterministik).
///
/// Dipakai nanti untuk menghitung "uang terikat" — tagihan yang jatuh tempo
/// sebelum gajian berikutnya.
///
/// Kandidat pertama = tanggal [paymentDate] pada bulan [today], di-clamp ke
/// akhir bulan bila bulan itu lebih pendek (mis. paymentDate 31 di Februari
/// -> 28/29). Aturan maju:
/// - Bila kandidat **> today** (masih akan datang) -> kembalikan kandidat.
/// - Bila kandidat **<= today** (termasuk SAMA-HARI, gajian hari ini
///   dianggap sudah cair/lewat) -> maju ke bulan berikutnya, clamp lagi.
DateTime nextPayday({required DateTime today, required int paymentDate}) {
  final candidate = clampDayOfMonth(today.year, today.month, paymentDate);

  // Titik keputusan eksplisit: "candidate <= today" (Dart tak punya operator
  // `<=` untuk DateTime, jadi ditulis sebagai negasi `isAfter`). Kondisi ini
  // WAJIB mencakup kasus sama-hari (`isAtSameMomentAs`) — bila hanya
  // `!candidate.isAfter(today)` diubah jadi `candidate.isBefore(today)`,
  // kasus sama-hari akan salah kembali sebagai "belum lewat".
  final sudahLewatAtauSamaHari =
      candidate.isBefore(today) || candidate.isAtSameMomentAs(today);

  if (!sudahLewatAtauSamaHari) {
    // candidate > today -> masih akan datang, langsung dipakai.
    return candidate;
  }

  // candidate <= today (termasuk sama-hari) -> gajian bulan ini dianggap
  // sudah cair/lewat, maju ke bulan berikutnya.
  final next = DateTime(today.year, today.month + 1, 1);
  return clampDayOfMonth(next.year, next.month, paymentDate);
}
