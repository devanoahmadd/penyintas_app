// test/features/onboarding/presentation/cubit/profile_setup_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/onboarding/presentation/cubit/profile_setup_cubit.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';

class _MockRepo extends Mock implements PreferencesRepository {}

class _FakePrefs extends Fake implements PreferencesEntity {}

void main() {
  late _MockRepo repo;
  final tz = TimezoneResolver(const [
    TimezoneCity(
      city: 'Jakarta',
      country: 'ID',
      iana: 'Asia/Jakarta',
      gmt: '+07:00',
    ),
    TimezoneCity(
      city: 'Moscow',
      country: 'RU',
      iana: 'Europe/Moscow',
      gmt: '+03:00',
    ),
  ]);

  setUpAll(() => registerFallbackValue(_FakePrefs()));
  setUp(() {
    repo = _MockRepo();
    // B-5: cubit memanggil repo.read() saat init (prefill bahasa) — stub default
    // agar semua test deterministik (bukan null-deref yang tertelan try/catch).
    // Temuan 5: blocTest yang meng-assert daftar emisi eksak pakai `build(autoPrefill:
    // false)` → TAK bergantung pada "kebetulan dedup" (prefill emit 'id' == default).
    when(() => repo.read()).thenAnswer((_) async => PreferencesEntity.defaults);
  });

  ProfileSetupCubit build({bool autoPrefill = true}) =>
      ProfileSetupCubit(repo: repo, tz: tz, autoPrefill: autoPrefill);

  test('pilih negara → reset kota & timezone fallback', () {
    final c = build();
    c.setCurrentCity('Jakarta');
    c.setCurrentCountry('RU');
    expect(c.state.currentCity, isNull);
  });

  test('pilih kota → derive IANA', () {
    final c = build()..setCurrentCountry('RU');
    c.setCurrentCity('Moscow');
    expect(c.state.timezone, 'Europe/Moscow');
  });

  test('toggle perantau ON → reveal asal + isPerantau true', () {
    final c = build();
    c.togglePerantau(true);
    expect(c.state.isPerantau, true);
  });

  test('setName: clamp ≤80 menyamai rules (B-4: cegah silent mirror-fail)', () {
    final c = build()..setName('x' * 200);
    expect(c.state.displayName!.length, 80);
  });

  test('toggle OFF → home=current (invariant A10)', () {
    final c = build()..setCurrentCountry('RU');
    c
      ..togglePerantau(true)
      ..setHomeCountry('ID')
      ..togglePerantau(false);
    expect(c.state.isPerantau, false);
    expect(c.state.homeCountry, 'RU'); // = current
  });

  test('prefill bahasa dari preferences tersimpan (B-5)', () async {
    when(() => repo.read()).thenAnswer(
      (_) async => PreferencesEntity.defaults.copyWith(language: 'en'),
    );
    final c = build(); // autoPrefill default → prefill() jalan
    await Future<void>.delayed(Duration.zero); // tunggu prefill()
    expect(c.state.language, 'en');
  });

  blocTest<ProfileSetupCubit, ProfileSetupState>(
    'save(): OFF → entity home=current, base/home IDR, profileCompleted true',
    build: () {
      when(() => repo.save(any())).thenAnswer((_) async => const Right(unit));
      // Temuan 5: autoPrefill:false → emisi deterministik (tanpa prefill async race)
      return build(autoPrefill: false)
        ..setCurrentCountry('RU')
        ..setCurrentCity('Moscow');
    },
    act: (c) => c.save(),
    verify: (_) {
      final captured =
          verify(() => repo.save(captureAny())).captured.single
              as PreferencesEntity;
      expect(captured.profileCompleted, true);
      expect(captured.timezone, 'Europe/Moscow');
      expect(captured.baseCurrency, 'IDR');
      expect(captured.homeCurrency, 'IDR');
      expect(captured.homeCountry, 'RU'); // OFF → home=current
      expect(captured.currentCountry, 'RU');
    },
  );

  blocTest<ProfileSetupCubit, ProfileSetupState>(
    'save() sukses → state.saved true',
    build: () {
      when(() => repo.save(any())).thenAnswer((_) async => const Right(unit));
      return build(
        autoPrefill: false,
      ); // Temuan 5: emisi eksak tanpa prefill race
    },
    act: (c) => c.save(),
    expect: () => [
      isA<ProfileSetupState>().having((s) => s.saving, 'saving', true),
      isA<ProfileSetupState>().having((s) => s.saved, 'saved', true),
    ],
  );

  test('save() re-entran: panggil 2x cepat → repo.save 1x (B-8)', () async {
    when(() => repo.save(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Right(unit);
    });
    final c = build();
    final f1 = c.save(); // saving=true (emit sinkron)
    final f2 = c.save(); // state.saving==true → no-op
    await Future.wait([f1, f2]);
    verify(() => repo.save(any())).called(1);
  });
}
