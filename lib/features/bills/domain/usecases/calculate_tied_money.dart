import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/next_payday.dart';

/// Hasil hitung "uang terikat" vs "sisa aman".
class TiedMoney {
  const TiedMoney({required this.tied, required this.safe});

  /// Total tagihan yang jatuh tempo SEBELUM gajian berikutnya.
  final int tied;

  /// Saldo dikurangi [tied] — uang yang benar-benar bebas dipakai.
  /// Bisa NEGATIF bila tagihan melebihi saldo (sinyal jujur, jangan di-clamp).
  final int safe;
}

/// MURNI: hitung uang terikat pada horizon sampai gajian berikutnya.
///
/// `tied` = Σ `estimatedAmount` bill aktif dengan `dueDate` **sebelum**
/// `nextPayday(today, paymentDate)` — bill yang jatuh tempo TEPAT pada atau
/// SESUDAH hari gajian tidak dihitung (sudah tertutup pemasukan berikutnya).
///
/// KONTRAK CALLER: fungsi ini **tidak** memfilter [BillStatus] sendiri —
/// pemanggil WAJIB hanya meneruskan bill berstatus `active` lewat
/// [activeBills]. Meneruskan bill `completed` membuatnya ikut terhitung
/// sebagai uang terikat (sisa aman jadi lebih kecil dari seharusnya).
TiedMoney calculateTiedMoney({
  required List<BillEntity> activeBills,
  required DateTime today,
  required int paymentDate,
  required int balance,
}) {
  final horizon = nextPayday(today: today, paymentDate: paymentDate);
  final tied = activeBills
      // Titik keputusan: `isBefore` (strict `<`) — bill tepat di hari gajian
      // TIDAK terikat. Mengubahnya jadi `<=` mengubah semantik horizon.
      .where((b) => b.dueDate.isBefore(horizon))
      .fold(0, (sum, b) => sum + b.estimatedAmount);
  return TiedMoney(tied: tied, safe: balance - tied);
}
