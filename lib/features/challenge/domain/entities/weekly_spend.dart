import 'package:equatable/equatable.dart';

/// Satu baris hasil proyeksi: total belanja OPERASIONAL satu kategori dalam
/// satu minggu kalender.
///
/// "Operasional" di fitur ini berarti `type == 'expense' && !isFixed &&
/// sourceBillId == null` (D19). Syarat ketiga sengaja berbeda dari DTL:
/// DTL mengukur uang yang keluar, tantangan mengukur belanja yang bisa ditekan.
class WeeklySpend extends Equatable {
  const WeeklySpend({
    required this.weekKey,
    required this.category,
    required this.amount,
  });

  /// dayKey Senin minggu itu (yyyymmdd).
  final int weekKey;
  final String category;
  final int amount;

  @override
  List<Object> get props => [weekKey, category, amount];
}
