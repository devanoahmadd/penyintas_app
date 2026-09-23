import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';

/// Model data satu baris tantangan — jembatan antara baris Drift
/// [WeeklyChallenge] dan dokumen Firestore `users/{uid}/challenges/{weekKey}`.
class ChallengeModel {
  const ChallengeModel({
    required this.weekKey,
    required this.category,
    required this.targetAmount,
    required this.baselineAmount,
    required this.status,
    required this.finalSpent,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
  });

  final int weekKey;
  final String? category;
  final int? targetAmount;
  final int? baselineAmount;
  final ChallengeStatus status;
  final int? finalSpent;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChallengeModel.fromRow(WeeklyChallenge r) => ChallengeModel(
    weekKey: r.weekKey,
    category: r.category,
    targetAmount: r.targetAmount,
    baselineAmount: r.baselineAmount,
    status: r.status,
    finalSpent: r.finalSpent,
    timezone: r.timezone,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  factory ChallengeModel.fromFirestore(
    Map<String, dynamic> j, {
    required int weekKey,
  }) => ChallengeModel(
    weekKey: weekKey,
    category: j['category'] as String?,
    targetAmount: (j['targetAmount'] as num?)?.toInt(),
    baselineAmount: (j['baselineAmount'] as num?)?.toInt(),
    // U51 — fallback WAJIB. Converter yang melempar mematikan seluruh
    // stream snapshot: satu dokumen asing dari versi app lebih baru bikin
    // halaman kosong permanen di device versi lama.
    status: const ChallengeStatusConverter().fromSql(
      (j['status'] as String?) ?? 'unknown',
    ),
    finalSpent: (j['finalSpent'] as num?)?.toInt(),
    timezone: (j['timezone'] as String?) ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      ((j['createdAt'] as num?) ?? 0).toInt(),
      isUtc: true,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      ((j['updatedAt'] as num?) ?? 0).toInt(),
      isUtc: true,
    ),
  );

  /// Field yang null DIHILANGKAN, bukan dikirim sebagai null — rules memvalidasi
  /// tipe hanya bila field hadir, dan baris `held` memang tak punya ketiganya.
  Map<String, dynamic> toFirestore() => {
    'weekKey': weekKey,
    if (category != null) 'category': category,
    if (targetAmount != null) 'targetAmount': targetAmount,
    if (baselineAmount != null) 'baselineAmount': baselineAmount,
    'status': const ChallengeStatusConverter().toSql(status),
    if (finalSpent != null) 'finalSpent': finalSpent,
    'timezone': timezone,
    'createdAt': createdAt.millisecondsSinceEpoch,
    // D23 — KOLOM, bukan waktu push. Kalau diisi waktu push, baris yang
    // lama mengantre mendarat sebagai yang termuda dan presedensi terbalik.
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    // resultSeenAt TIDAK PERNAH dikirim — ia kolom lokal-saja (D11).
  };

  /// [keepResultSeenAt] WAJIB diisi nilai lokal saat menyimpan hasil tarikan
  /// (T17 aturan 3): "tidak dikirim" tidak otomatis berarti "tidak tertimpa".
  ///
  /// `required` walau nullable — sengaja. Nilai bawaan membuat pemanggil yang
  /// lupa memikirkannya tetap kompilasi, dan akibatnya senyap: kartu hasil yang
  /// sudah user tutup muncul lagi setiap kali sinkron berjalan.
  WeeklyChallengesCompanion toCompanion({
    required DateTime? keepResultSeenAt,
    required bool isSynced,
  }) => WeeklyChallengesCompanion(
    weekKey: Value(weekKey),
    category: Value(category),
    targetAmount: Value(targetAmount),
    baselineAmount: Value(baselineAmount),
    status: Value(status),
    finalSpent: Value(finalSpent),
    timezone: Value(timezone),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    resultSeenAt: Value(keepResultSeenAt),
    isSynced: Value(isSynced),
  );
}
