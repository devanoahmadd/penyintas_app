import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_local_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

void main() {
  late AppDatabase db;
  late PreferencesLocalDatasourceImpl ds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = PreferencesLocalDatasourceImpl(db);
  });
  tearDown(() => db.close());

  test('read() pada DB baru → defaults (row ter-seed onCreate, C2)', () async {
    // C2: onCreate men-seed singleton id=1 → read() TAK pernah null di DB normal.
    final got = await ds.read();
    expect(got, isNotNull);
    expect(got!.language, 'id');
    expect(got.baseCurrency, 'IDR');
    expect(got.profileCompleted, false);
  });

  test('read() saat row benar-benar tak ada → null (defensif)', () async {
    await db.delete(db.preferences).go(); // hapus row seeded
    expect(await ds.read(), isNull);
  });

  test('write lalu read round-trip', () async {
    final p = PreferencesEntity.defaults.copyWith(
      timezone: 'Europe/Moscow',
      currentCountry: 'RU',
      currentCity: 'Moscow',
      isPerantau: true,
      profileCompleted: true,
    );
    await ds.write(p);
    final got = await ds.read();
    expect(got!.timezone, 'Europe/Moscow');
    expect(got.currentCountry, 'RU');
    expect(got.isPerantau, true);
    expect(got.profileCompleted, true);
    expect(got.baseCurrency, 'IDR'); // Spec 1
  });

  test('write idempotent (singleton id=1, overwrite)', () async {
    await ds.write(PreferencesEntity.defaults.copyWith(language: 'en'));
    await ds.write(PreferencesEntity.defaults.copyWith(language: 'id'));
    final got = await ds.read();
    expect(got!.language, 'id');
    final count = await db.select(db.preferences).get();
    expect(count.length, 1); // tetap satu row
  });

  test('T-1: write() menandai dirty → hasPendingMirror true', () async {
    await ds.write(PreferencesEntity.defaults.copyWith(profileCompleted: true));
    expect(await ds.hasPendingMirror(), true);
  });

  test('T-1: markMirrored() → clean (hasPendingMirror false)', () async {
    await ds.write(PreferencesEntity.defaults.copyWith(profileCompleted: true));
    await ds.markMirrored(DateTime.now().millisecondsSinceEpoch);
    expect(await ds.hasPendingMirror(), false);
  });

  test(
    'CF-3 / T-1: write LAGI setelah markMirrored → dirty kembali (siklus penuh anti-clobber)',
    () async {
      // Invarian jantung anti-clobber: SETIAP write() me-null-kan lastSyncedAtMs
      // (datasource:61) = dirty ulang. Kalau suatu refactor membuat write()
      // mempertahankan lastSyncedAtMs, launch-bersih tak akan mirror edit baru →
      // cloud & local diverge senyap. Test ini menjaga siklus penuh, bukan cuma satu sisi.
      await ds.write(
        PreferencesEntity.defaults.copyWith(profileCompleted: true),
      );
      await ds.markMirrored(DateTime.now().millisecondsSinceEpoch);
      expect(await ds.hasPendingMirror(), false); // clean setelah mirror sukses
      await ds.write(
        PreferencesEntity.defaults.copyWith(displayName: 'Edit baru'),
      );
      expect(
        await ds.hasPendingMirror(),
        true,
      ); // write berikutnya WAJIB me-dirty ulang
    },
  );
}
