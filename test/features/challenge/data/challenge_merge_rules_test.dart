import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/data/repositories/challenge_repository_impl.dart';
import 'package:penyintas_app/features/challenge/data/models/challenge_model.dart';

void main() {
  test('U49 · status terselesaikan menang atas active', () {
    expect(
      mergeRank(ChallengeStatus.active),
      lessThan(mergeRank(ChallengeStatus.skipped)),
    );
    for (final s in [
      ChallengeStatus.achieved,
      ChallengeStatus.missed,
      ChallengeStatus.held,
      ChallengeStatus.skipped,
    ]) {
      expect(
        mergeRank(s),
        greaterThan(mergeRank(ChallengeStatus.active)),
        reason: '$s harus menang atas active',
      );
    }
  });

  test('U49 · peringkat sama → updatedAt terbesar menang', () {
    final lama = DateTime.utc(2026, 9, 7);
    final baru = DateTime.utc(2026, 9, 8);
    expect(
      remoteMenang(
        lokalStatus: ChallengeStatus.achieved,
        lokalUpdatedAt: lama,
        remoteStatus: ChallengeStatus.missed,
        remoteUpdatedAt: baru,
      ),
      isTrue,
    );
    expect(
      remoteMenang(
        lokalStatus: ChallengeStatus.achieved,
        lokalUpdatedAt: baru,
        remoteStatus: ChallengeStatus.missed,
        remoteUpdatedAt: lama,
      ),
      isFalse,
    );
  });

  test('U116 · updatedAt remote disimpan APA ADANYA, bukan waktu tarik', () {
    // Kalau diisi waktu tarik, semua baris remote jadi termuda dan presedensi
    // rusak pada sinkron berikutnya.
    final remote = DateTime.utc(2026, 9, 8, 3);
    final c = ChallengeModel.fromFirestore({
      'status': 'achieved',
      'timezone': 'WIB',
      'createdAt': 0,
      'updatedAt': remote.millisecondsSinceEpoch,
    }, weekKey: 20260907).toCompanion(keepResultSeenAt: null, isSynced: true);
    expect(c.updatedAt.value, remote);
  });

  group('zonaAudit · jejak audit zona waktu', () {
    test('nama zona device dipakai APA ADANYA', () {
      // Bentuk yang sama dengan `streak_day_marks.timezone`: singkatan device,
      // bukan id IANA. Konsistensi lintas-fitur A4 yang dijaga di sini.
      expect(zonaAudit('WIB', const Duration(hours: 7)), 'WIB');
      expect(zonaAudit('+07', const Duration(hours: 7)), '+07');
    });

    test('nama zona KOSONG jatuh ke offset UTC — tak pernah string kosong', () {
      // `firestore.rules` menuntut `timezone.size() > 0`. String kosong membuat
      // dokumennya ditolak SELAMANYA: dorongan gagal diam-diam dan barisnya
      // mengendap di antrian tanpa satu pun pesan ke user.
      expect(zonaAudit('', const Duration(hours: 7)), 'UTC+07:00');
      expect(zonaAudit('', const Duration(hours: 5, minutes: 30)), 'UTC+05:30');
      expect(zonaAudit('', const Duration(hours: -8)), 'UTC-08:00');
      expect(zonaAudit('', Duration.zero), 'UTC+00:00');
    });
  });

  test('U49 · remote active TIDAK membangkitkan minggu yang sudah tuntas', () {
    // Meski updatedAt remote lebih besar — peringkat status menang lebih dulu.
    expect(
      remoteMenang(
        lokalStatus: ChallengeStatus.skipped,
        lokalUpdatedAt: DateTime.utc(2026, 9, 7),
        remoteStatus: ChallengeStatus.active,
        remoteUpdatedAt: DateTime.utc(2026, 9, 9),
      ),
      isFalse,
    );
  });
}
