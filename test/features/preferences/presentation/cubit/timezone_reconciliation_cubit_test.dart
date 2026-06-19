// test/features/preferences/presentation/cubit/timezone_reconciliation_cubit_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:penyintas_app/features/preferences/presentation/cubit/timezone_reconciliation_cubit.dart';

class _MockRepo extends Mock implements PreferencesRepository {}

void main() {
  late _MockRepo repo;
  final tz = TimezoneResolver(const [
    TimezoneCity(city: 'Jakarta', country: 'ID', iana: 'Asia/Jakarta', gmt: '+07:00'),
    TimezoneCity(city: 'Moscow', country: 'RU', iana: 'Europe/Moscow', gmt: '+03:00'),
  ]);

  setUpAll(() => registerFallbackValue(PreferencesEntity.defaults));
  setUp(() => repo = _MockRepo());

  TimezoneReconciliationCubit build(String deviceTz) => TimezoneReconciliationCubit(
        repo: repo, tz: tz, getDeviceTimezone: () async => deviceTz,
      );

  test('device == tersimpan → tak ada prompt', () async {
    when(() => repo.read()).thenAnswer((_) async =>
        PreferencesEntity.defaults.copyWith(timezone: 'Asia/Jakarta', currentCity: 'Jakarta'));
    final c = build('Asia/Jakarta');
    await c.check();
    expect(c.state.prompt, isNull);
  });

  test('device != tersimpan → prompt dgn label device + label tersimpan (currentCity konsisten)', () async {
    when(() => repo.read()).thenAnswer((_) async => PreferencesEntity.defaults
        .copyWith(timezone: 'Asia/Jakarta', currentCity: 'Jakarta', currentCountry: 'ID'));
    final c = build('Europe/Moscow');
    await c.check();
    expect(c.state.prompt, isNotNull);
    expect(c.state.prompt!.deviceTz, 'Europe/Moscow');
    expect(c.state.prompt!.deviceLabel, 'Moscow · GMT+3'); // labelForIana
    expect(c.state.prompt!.storedLabel, 'Jakarta');         // F-D5b: kota cocok zona → pakai kota
  });

  test('confirm → repo.save dgn timezone device, prompt hilang', () async {
    when(() => repo.read()).thenAnswer((_) async =>
        PreferencesEntity.defaults.copyWith(timezone: 'Asia/Jakarta', currentCity: 'Jakarta'));
    when(() => repo.save(any())).thenAnswer((_) async => const Right(unit));
    final c = build('Europe/Moscow');
    await c.check();
    await c.confirm();
    final saved = verify(() => repo.save(captureAny())).captured.single
        as PreferencesEntity;
    expect(saved.timezone, 'Europe/Moscow');
    expect(c.state.prompt, isNull);
  });

  test('getDeviceTimezone throw → tak ada prompt (tak crash launch)', () async {
    when(() => repo.read()).thenAnswer((_) async => PreferencesEntity.defaults);
    final c = TimezoneReconciliationCubit(
      repo: repo, tz: tz, getDeviceTimezone: () async => throw Exception('no plugin'),
    );
    await c.check();
    expect(c.state.prompt, isNull);
  });

  test('dismiss → prompt hilang tanpa menyimpan', () async {
    when(() => repo.read()).thenAnswer((_) async =>
        PreferencesEntity.defaults.copyWith(timezone: 'Asia/Jakarta'));
    final c = build('Europe/Moscow');
    await c.check();
    expect(c.state.prompt, isNotNull); // prompt muncul dulu (device != tersimpan)
    c.dismiss();
    expect(c.state.prompt, isNull);
    verifyNever(() => repo.save(any()));
  });

  test('F-D5b label basi: currentCity tak cocok timezone → pakai labelForIana, bukan kota basi', () async {
    // Pasca-confirm: timezone bergeser ke Moscow tapi currentCity masih Jakarta (basi).
    when(() => repo.read()).thenAnswer((_) async => PreferencesEntity.defaults.copyWith(
        timezone: 'Europe/Moscow', currentCity: 'Jakarta', currentCountry: 'ID'));
    final c = build('Asia/Jakarta'); // device beda dari Moscow tersimpan → prompt
    await c.check();
    expect(c.state.prompt!.storedLabel, 'Moscow · GMT+3'); // bukan 'Jakarta' basi
  });

  test('F-D5 snooze: setelah dismiss zona sama → check ulang TAK prompt (anti-nag remount)', () async {
    when(() => repo.read()).thenAnswer((_) async =>
        PreferencesEntity.defaults.copyWith(timezone: 'Asia/Jakarta'));
    final c = build('Europe/Moscow');
    await c.check();
    expect(c.state.prompt, isNotNull);
    c.dismiss();
    await c.check(); // simulasi remount dashboard pada instance singleton yang sama
    expect(c.state.prompt, isNull,
        reason: 'Moscow di-snooze → tak ditawarkan lagi sesi ini');
  });

  test('F-D5c confirm bersihkan snooze: edge travel X→dismiss→Y→confirm→balik X di-prompt lagi', () async {
    var device = 'Europe/Moscow';
    var stored = 'Asia/Jakarta';
    when(() => repo.read()).thenAnswer(
        (_) async => PreferencesEntity.defaults.copyWith(timezone: stored));
    when(() => repo.save(any())).thenAnswer((inv) async {
      stored = (inv.positionalArguments.first as PreferencesEntity).timezone;
      return const Right(unit);
    });
    final c = TimezoneReconciliationCubit(
      repo: repo, tz: tz, getDeviceTimezone: () async => device,
    );

    await c.check();          // Moscow vs Jakarta → prompt
    c.dismiss();              // snooze = Moscow
    device = 'America/New_York';
    await c.check();          // zona baru (tak ter-snooze) → prompt
    expect(c.state.prompt!.deviceTz, 'America/New_York');
    await c.confirm();        // stored → New_York; snooze dibersihkan (F-D5c)

    device = 'Europe/Moscow'; // balik ke zona yg DULU di-snooze
    await c.check();
    expect(c.state.prompt, isNotNull,
        reason: 'snooze lama dibersihkan confirm → Moscow di-prompt lagi');
    expect(c.state.prompt!.deviceTz, 'Europe/Moscow');
  });
}
