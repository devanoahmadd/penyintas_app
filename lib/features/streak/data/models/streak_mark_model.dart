/// Satu dokumen `users/{uid}/streak_marks/{yyyyMMdd}`.
///
/// SATU DOKUMEN PER HARI, bukan map bulanan. Alasannya bukan estetika:
/// `SyncDispatcher` hanya mengenal set / set-merge / hapus-dokumen, dan
/// `SyncQueue.data` ber-JSON — `FieldValue.delete()` tidak JSON-serializable,
/// jadi menghapus SATU key di dalam map tidak punya jalur sama sekali.
/// Dengan map bulanan, undo yang sudah tersinkron akan hidup lagi saat
/// reinstall.
class StreakMarkModel {
  const StreakMarkModel({
    required this.dayKey,
    required this.markedAt,
    required this.timezone,
  });

  final int dayKey;
  final DateTime markedAt;
  final String timezone;

  String get docId => dayKey.toString();

  /// [updatedAtMs] disuntik (bukan `DateTime.now()` di dalam) supaya bentuk
  /// dokumen bisa diuji deterministik.
  Map<String, dynamic> toFirestore({required int updatedAtMs}) => {
    'dayKey': dayKey,
    'markedAt': markedAt.toUtc().millisecondsSinceEpoch,
    'timezone': timezone,
    'updatedAt': updatedAtMs,
  };

  factory StreakMarkModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) => StreakMarkModel(
    // Fallback ke doc-id hanya jalan kalau field 'dayKey' HILANG dari data.
    // Kalau field itu ADA tapi bertipe salah, `as num?` melempar TypeError
    // sebelum sempat jatuh ke fallback — dan itu memang diinginkan: sync
    // harus tahu ada masalah, bukan menutupinya diam-diam di balik doc-id.
    dayKey: (data['dayKey'] as num?)?.toInt() ?? int.parse(docId),
    markedAt: DateTime.fromMillisecondsSinceEpoch(
      (data['markedAt'] as num?)?.toInt() ?? 0,
      isUtc: true,
    ),
    timezone: (data['timezone'] as String?) ?? 'UTC',
  );
}
