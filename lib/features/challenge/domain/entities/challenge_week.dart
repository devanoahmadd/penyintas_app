import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';

/// Satu minggu tantangan, sebagaimana UI dan domain membutuhkannya.
///
/// SENGAJA lebih sempit dari baris Drift `WeeklyChallenge`: `timezone`,
/// `createdAt`, `updatedAt`, dan `isSynced` tidak ikut. Ketiganya milik
/// lapisan data — `updatedAt` melayani presedensi merge (D23), `isSynced`
/// melayani antrian dorong — dan tak satu pun pernah menentukan apa yang
/// dilihat user. Membawanya ke sini berarti `markSynced` memicu rebuild kartu
/// yang isinya tidak berubah sama sekali.
///
/// Pemetaan baris → entity terjadi di SATU tempat: `challenge_local_datasource`
/// (Task 6). Kalau suatu saat ada tempat kedua, itu tanda entity ini kurang
/// lengkap — tambah field di sini, jangan tambah pemeta.
class ChallengeWeek extends Equatable {
  const ChallengeWeek({
    required this.weekKey,
    required this.category,
    required this.targetAmount,
    required this.baselineAmount,
    required this.status,
    required this.finalSpent,
    required this.resolvedAt,
    required this.resultSeenAt,
  });

  /// dayKey Senin minggu itu (yyyymmdd).
  final int weekKey;

  /// NULL untuk minggu `held`/`skipped` yang tak pernah jadi tantangan (§3).
  final String? category;
  final int? targetAmount;
  final int? baselineAmount;

  final ChallengeStatus status;

  /// Dibekukan saat evaluasi; null selagi `active`.
  final int? finalSpent;
  final DateTime? resolvedAt;

  /// D11 — lokal saja. Ikut ke domain karena kartu hasil bergantung padanya.
  final DateTime? resultSeenAt;

  @override
  List<Object?> get props => [
    weekKey,
    category,
    targetAmount,
    baselineAmount,
    status,
    finalSpent,
    resolvedAt,
    resultSeenAt,
  ];
}
