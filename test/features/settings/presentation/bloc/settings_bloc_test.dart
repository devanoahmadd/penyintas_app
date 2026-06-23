import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:penyintas_app/features/settings/presentation/bloc/settings_bloc.dart';

class _MockPrefsRepo extends Mock implements PreferencesRepository {}

void main() {
  late AppDatabase db;
  late _MockPrefsRepo repo;

  setUpAll(() => registerFallbackValue(PreferencesEntity.defaults));
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = _MockPrefsRepo();
  });
  tearDown(() => db.close());

  blocTest<SettingsBloc, SettingsState>(
    'SettingsLoaded: language dibaca dari PreferencesRepository (bukan app_settings)',
    setUp: () => when(() => repo.read())
        .thenAnswer((_) async => PreferencesEntity.defaults.copyWith(language: 'en')),
    build: () => SettingsBloc(db, repo),
    act: (b) => b.add(const SettingsLoaded()),
    expect: () =>
        [isA<SettingsState>().having((s) => s.locale, 'locale', 'en')],
  );

  blocTest<SettingsBloc, SettingsState>(
    'ChangeLanguage: tulis ke PreferencesRepository, BUKAN app_settings',
    setUp: () {
      when(() => repo.read()).thenAnswer((_) async => PreferencesEntity.defaults);
      when(() => repo.save(any())).thenAnswer((_) async => const Right(unit));
    },
    build: () => SettingsBloc(db, repo),
    act: (b) => b.add(const ChangeLanguage('en')),
    expect: () =>
        [isA<SettingsState>().having((s) => s.locale, 'locale', 'en')],
    verify: (_) async {
      final saved = verify(() => repo.save(captureAny())).captured.single
          as PreferencesEntity;
      expect(saved.language, 'en');
      // L1: language TAK pernah ditulis ke app_settings (single source = preferences).
      final row = await (db.select(db.appSettings)..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      expect(row, isNull, reason: 'language bukan urusan app_settings pasca-cutover');
    },
  );

  blocTest<SettingsBloc, SettingsState>(
    'SettingsLoaded: language tak dikenal di preferences → di-CLAMP ke id (M2)',
    // seed locale 'en' agar hasil clamp 'fr'→'id' MERUPAKAN perubahan. Kalau mulai
    // dari 'id' default, emit 'id' == state → bloc dedup → nol emisi → test palsu-lulus/gagal.
    seed: () => const SettingsState(themeMode: ThemeMode.system, locale: 'en'),
    setUp: () => when(() => repo.read()).thenAnswer(
        (_) async => PreferencesEntity.defaults.copyWith(language: 'fr')),
    build: () => SettingsBloc(db, repo),
    act: (b) => b.add(const SettingsLoaded()),
    expect: () =>
        [isA<SettingsState>().having((s) => s.locale, 'locale', 'id')],
  );

  blocTest<SettingsBloc, SettingsState>(
    'ChangeLanguage: save gagal (Left) → locale REVERT, tak ada phantom-sukses (M1)',
    setUp: () {
      when(() => repo.read())
          .thenAnswer((_) async => PreferencesEntity.defaults); // language 'id'
      when(() => repo.save(any()))
          .thenAnswer((_) async => const Left(CacheFailure('disk penuh')));
    },
    build: () => SettingsBloc(db, repo),
    act: (b) => b.add(const ChangeLanguage('en')),
    expect: () => [
      isA<SettingsState>().having((s) => s.locale, 'optimistic', 'en'),
      isA<SettingsState>().having((s) => s.locale, 'reverted', 'id'),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'ChangeTheme: persist ke app_settings, TIDAK menyentuh preferences',
    setUp: () =>
        when(() => repo.read()).thenAnswer((_) async => PreferencesEntity.defaults),
    build: () => SettingsBloc(db, repo),
    act: (b) => b.add(const ChangeTheme(ThemeMode.dark)),
    expect: () =>
        [isA<SettingsState>().having((s) => s.themeMode, 'theme', ThemeMode.dark)],
    verify: (_) async {
      verifyNever(() => repo.save(any()));
      final row = await (db.select(db.appSettings)..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      expect(row?.themeMode, 'dark');
    },
  );
}
