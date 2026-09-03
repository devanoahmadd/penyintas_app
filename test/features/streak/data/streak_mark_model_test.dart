import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/streak/data/models/streak_mark_model.dart';

void main() {
  final mark = StreakMarkModel(
    dayKey: 20260902,
    markedAt: DateTime.utc(2026, 9, 2, 3, 15),
    timezone: 'Asia/Jakarta',
  );

  test('docId sama dengan dayKey — dokumen per hari, bukan per bulan', () {
    expect(mark.docId, '20260902');
  });

  test('toFirestore memakai millis dan menyertakan updatedAt yang disuntik', () {
    final map = mark.toFirestore(updatedAtMs: 1756800000000);
    expect(map['dayKey'], 20260902);
    expect(map['markedAt'], DateTime.utc(2026, 9, 2, 3, 15).millisecondsSinceEpoch);
    expect(map['timezone'], 'Asia/Jakarta');
    expect(map['updatedAt'], 1756800000000);
    expect(map.containsKey('viaClockCorrection'), isFalse,
        reason: 'kolom lokal — tak pernah dikirim ke Firestore');
  });

  test('fromFirestore membaca kembali bentuk yang sama', () {
    final map = mark.toFirestore(updatedAtMs: 1);
    final pulang = StreakMarkModel.fromFirestore('20260902', map);
    expect(pulang.dayKey, mark.dayKey);
    expect(pulang.markedAt.toUtc(), mark.markedAt);
    expect(pulang.timezone, mark.timezone);
  });

  test('fromFirestore memakai doc-id saat field dayKey rusak', () {
    final pulang = StreakMarkModel.fromFirestore('20260903', const {
      'markedAt': 0,
      'timezone': 'UTC',
    });
    expect(pulang.dayKey, 20260903);
  });
}
