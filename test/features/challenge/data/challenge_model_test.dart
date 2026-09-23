import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/data/models/challenge_model.dart';

final _dibuat = DateTime.utc(2026, 9, 7, 2);
final _diubah = DateTime.utc(2026, 9, 8, 3);

ChallengeModel _model({
  String? kategori = 'food',
  int? target = 115000,
  int? basis = 140000,
  ChallengeStatus status = ChallengeStatus.active,
  int? finalSpent,
}) => ChallengeModel(
  weekKey: 20260907,
  category: kategori,
  targetAmount: target,
  baselineAmount: basis,
  status: status,
  finalSpent: finalSpent,
  timezone: 'WIB',
  createdAt: _dibuat,
  updatedAt: _diubah,
);

void main() {
  test('payload memuat seluruh field ber-payload', () {
    final j = _model().toFirestore();
    expect(j['weekKey'], 20260907);
    expect(j['category'], 'food');
    expect(j['targetAmount'], 115000);
    expect(j['baselineAmount'], 140000);
    expect(j['status'], 'active');
    expect(j['timezone'], 'WIB');
    expect(j['createdAt'], _dibuat.millisecondsSinceEpoch);
    expect(j['updatedAt'], _diubah.millisecondsSinceEpoch);
  });

  test('U35 · baris held: kategori/target/basis ABSEN dari payload', () {
    final j = _model(
      kategori: null,
      target: null,
      basis: null,
      status: ChallengeStatus.held,
    ).toFirestore();
    expect(j.containsKey('category'), isFalse);
    expect(j.containsKey('targetAmount'), isFalse);
    expect(j.containsKey('baselineAmount'), isFalse);
    expect(j['status'], 'held');
  });

  test('finalSpent absen selama active, hadir setelah dievaluasi', () {
    expect(_model().toFirestore().containsKey('finalSpent'), isFalse);
    final selesai = _model(
      status: ChallengeStatus.achieved,
      finalSpent: 118500,
    );
    expect(selesai.toFirestore()['finalSpent'], 118500);
  });

  test('resultSeenAt TIDAK PERNAH dikirim', () {
    final j = _model().toFirestore();
    expect(j.containsKey('resultSeenAt'), isFalse);
  });

  test('U51 · status asing dari remote → unknown, tidak melempar', () {
    final m = ChallengeModel.fromFirestore({
      'status': 'paused_v17',
      'timezone': 'WIB',
      'createdAt': 0,
      'updatedAt': 0,
    }, weekKey: 20260907);
    expect(m.status, ChallengeStatus.unknown);
  });

  // Ditambahkan saat verifikasi sabotase Langkah 8 butir 6: kasus 'paused_v17'
  // di atas TIDAK menguji fallback `?? 'unknown'` di fromFirestore — nilai
  // asing itu sudah ditangani oleh fallback internal ChallengeStatusConverter
  // sendiri (app_database.dart). Guard `?? 'unknown'` di fromFirestore
  // melindungi kasus lain: field 'status' yang ABSEN dari dokumen (bukan
  // sekadar bernilai asing) — cast `null as String` tanpanya akan melempar.
  test('U51b · status ABSEN dari payload remote → unknown, tidak melempar', () {
    final m = ChallengeModel.fromFirestore({
      'timezone': 'WIB',
      'createdAt': 0,
      'updatedAt': 0,
    }, weekKey: 20260907);
    expect(m.status, ChallengeStatus.unknown);
  });

  test('U50 · toCompanion mempertahankan resultSeenAt lokal', () {
    final lokal = DateTime.utc(2026, 9, 9);
    final c = _model().toCompanion(keepResultSeenAt: lokal, isSynced: true);
    expect(c.resultSeenAt.value, lokal);
  });
}
