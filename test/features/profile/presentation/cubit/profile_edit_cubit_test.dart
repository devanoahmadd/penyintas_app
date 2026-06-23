// test/features/profile/presentation/cubit/profile_edit_cubit_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:penyintas_app/features/profile/presentation/cubit/profile_edit_cubit.dart';

class _MockRepo extends Mock implements PreferencesRepository {}

void main() {
  late _MockRepo repo;
  final tz = TimezoneResolver(const [
    TimezoneCity(city: 'Jakarta', country: 'ID', iana: 'Asia/Jakarta', gmt: '+07:00'),
    TimezoneCity(city: 'Moscow', country: 'RU', iana: 'Europe/Moscow', gmt: '+03:00'),
  ]);

  final loaded = PreferencesEntity.defaults.copyWith(
    displayName: 'Devano', language: 'en', currentCountry: 'ID',
    currentCity: 'Jakarta', profileCompleted: true,
  );

  setUpAll(() => registerFallbackValue(PreferencesEntity.defaults));
  setUp(() {
    repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => loaded);
    when(() => repo.save(any())).thenAnswer((_) async => const Right(unit));
  });

  ProfileEditCubit build() => ProfileEditCubit(repo: repo, tz: tz);

  test('_load: draft terisi dari repo', () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    expect(c.state.loading, false);
    expect(c.state.draft!.displayName, 'Devano');
    expect(c.state.draft!.language, 'en');
  });

  test('setName clamp ≤80', () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    c.setName('x' * 100);
    expect(c.state.draft!.displayName!.length, 80);
  });

  test('ganti negara → kota direset null (timezone dipertahankan s/d pilih kota)', () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    c.setCurrentCountry('RU');
    expect(c.state.draft!.currentCountry, 'RU');
    expect(c.state.draft!.currentCity, isNull);
  });

  test('pilih kota → derive IANA', () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    c.setCurrentCountry('RU');
    c.setCurrentCity('Moscow');
    expect(c.state.draft!.timezone, 'Europe/Moscow');
  });

  test('togglePerantau OFF → home = current (invariant A10)', () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    c.setCurrentCountry('RU');
    c.togglePerantau(true);
    c.setHomeCountry('ID');
    c.togglePerantau(false);
    expect(c.state.draft!.homeCountry, 'RU'); // = current
    expect(c.state.draft!.homeCity, isNull);
    expect(c.state.draft!.isPerantau, false);
  });

  test('save: profileCompleted tetap true, language tak diubah, IDR-seragam', () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    c.setName('Baru');
    await c.save();
    final saved = verify(() => repo.save(captureAny())).captured.single
        as PreferencesEntity;
    expect(saved.displayName, 'Baru');
    expect(saved.profileCompleted, true);
    expect(saved.language, 'en');     // tak disentuh editor
    expect(saved.baseCurrency, 'IDR');
    expect(saved.homeCurrency, 'IDR');
    expect(c.state.saved, true);
    // M3: re-baseline pasca-simpan → tak ada "dirty" palsu yang memicu dialog buang
    // (sekaligus membuat canPop=true, pop sukses anti-deadlock).
    expect(c.state.isDirty, false);
  });

  test('save re-entran: panggilan kedua diabaikan saat saving', () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    final f1 = c.save();
    final f2 = c.save(); // saving==true → early-return
    await Future.wait<void>([f1, f2]);
    verify(() => repo.save(any())).called(1);
  });

  test('H1: load gagal → draft null + error; save() no-op (tak menimpa profil asli)',
      () async {
    when(() => repo.read()).thenThrow(Exception('db rusak'));
    final c = build();
    await Future<void>.delayed(Duration.zero);
    expect(c.state.draft, isNull, reason: 'tak fallback ke defaults');
    expect(c.state.error, isNotNull);
    await c.save();
    verifyNever(() => repo.save(any())); // nol tulisan defaults-over-profil
  });

  test('H2: save diblok setelah ganti negara sebelum kota dipilih (tz basi tak tersimpan)',
      () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    c.setCurrentCountry('RU'); // RU punya Moscow di dataset → kota wajib dipilih
    expect(c.state.currentLocationResolved, false);
    await c.save();
    verifyNever(() => repo.save(any()));
    expect(c.state.error, isNotNull);
  });

  test('H2: save lolos setelah pilih kota baru (resolved kembali true)', () async {
    final c = build();
    await Future<void>.delayed(Duration.zero);
    c.setCurrentCountry('RU');
    c.setCurrentCity('Moscow');
    expect(c.state.currentLocationResolved, true);
    await c.save();
    verify(() => repo.save(any())).called(1);
  });
}
