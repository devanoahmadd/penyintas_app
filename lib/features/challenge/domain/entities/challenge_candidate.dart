import 'package:equatable/equatable.dart';

/// Satu pilihan yang app sodorkan ke user (maksimal 3, T3).
///
/// `target` sudah dihitung dan ikut ditampilkan SEBELUM user memilih (§7.9):
/// meminta orang berkomitmen pada angka yang baru muncul setelah komitmennya
/// adalah pola gelap kecil yang gampang lolos.
class ChallengeCandidate extends Equatable {
  const ChallengeCandidate({
    required this.category,
    required this.baseline,
    required this.target,
  });

  final String category;
  final int baseline;
  final int target;

  @override
  List<Object> get props => [category, baseline, target];
}
