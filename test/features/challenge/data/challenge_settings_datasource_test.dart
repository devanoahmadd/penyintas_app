import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_settings_datasource.dart';

void main() {
  group('sakelar fitur · C4', () {
    late AppDatabase db;
    late ChallengeSettingsDatasource sakelar;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sakelar = ChallengeSettingsDatasourceImpl(db);
    });

    tearDown(() async => db.close());

    test('baris app_settings belum ada → false, bukan exception', () async {
      expect(await sakelar.isEnabled(), isFalse);
    });

    test('setEnabled(true) lalu isEnabled() → true', () async {
      await sakelar.setEnabled(true);
      expect(await sakelar.isEnabled(), isTrue);
    });

    test('S-B · watchEnabled meng-emit ulang saat sakelar berubah', () async {
      // Tanpa stream ini, menyalakan sakelar tidak merefresh tile maupun
      // halaman sampai ada perubahan tabel lain yang kebetulan memicu emit.
      final terlihat = <bool>[];
      final sub = sakelar.watchEnabled().listen(terlihat.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sakelar.setEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(terlihat.first, isFalse);
      expect(terlihat.last, isTrue);
    });

    test('setEnabled TIDAK menghapus kolom app_settings lain', () async {
      await db
          .into(db.appSettings)
          .insertOnConflictUpdate(
            const AppSettingsCompanion(
              id: Value(1),
              monthlyIncome: Value(3500000),
            ),
          );
      await sakelar.setEnabled(true);
      final row = await (db.select(
        db.appSettings,
      )..where((t) => t.id.equals(1))).getSingle();
      expect(row.monthlyIncome, 3500000);
      expect(row.challengeEnabled, isTrue);
    });
  });
}
