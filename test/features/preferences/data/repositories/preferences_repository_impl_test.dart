import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_local_datasource.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:penyintas_app/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

class _MockLocal extends Mock implements PreferencesLocalDatasource {}
class _MockRemote extends Mock implements PreferencesRemoteDatasource {}
class _FakePrefs extends Fake implements PreferencesEntity {}

void main() {
  late _MockLocal local;
  late _MockRemote remote;
  late PreferencesRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(_FakePrefs()));
  setUp(() {
    local = _MockLocal();
    remote = _MockRemote();
    repo = PreferencesRepositoryImpl(local: local, remote: remote);
    // T-1 default stubs (override per-test bila perlu).
    when(() => local.markMirrored(any())).thenAnswer((_) async {});
    when(() => local.hasPendingMirror()).thenAnswer((_) async => true);
  });

  test('read(): local ada → kembalikan local', () async {
    when(() => local.read()).thenAnswer(
        (_) async => PreferencesEntity.defaults.copyWith(timezone: 'Europe/Moscow'));
    final got = await repo.read();
    expect(got.timezone, 'Europe/Moscow');
  });

  test('read(): local kosong → defaults', () async {
    when(() => local.read()).thenAnswer((_) async => null);
    final got = await repo.read();
    expect(got, PreferencesEntity.defaults);
  });

  test('save(): tulis local LALU mirror LALU markMirrored, return Right(unit)', () async {
    when(() => local.write(any())).thenAnswer((_) async {});
    when(() => remote.mirror(any())).thenAnswer((_) async {});
    final r = await repo.save(PreferencesEntity.defaults);
    expect(r, const Right(unit));
    verifyInOrder([
      () => local.write(any()),
      () => remote.mirror(any()),
      () => local.markMirrored(any()), // T-1: tandai clean setelah mirror sukses
    ]);
  });

  test('save(): mirror gagal → local tetap tersimpan, return Right(unit) (non-fatal)', () async {
    when(() => local.write(any())).thenAnswer((_) async {});
    when(() => remote.mirror(any())).thenThrow(Exception('offline'));
    final r = await repo.save(PreferencesEntity.defaults);
    expect(r, const Right(unit));
    verify(() => local.write(any())).called(1);
    verifyNever(() => local.markMirrored(any())); // T-1: gagal → tetap dirty (retry launch)
  });

  test('save(): local gagal → Left(CacheFailure)', () async {
    when(() => local.write(any())).thenThrow(Exception('disk full'));
    final r = await repo.save(PreferencesEntity.defaults);
    expect(r.isLeft(), true);
    verifyNever(() => remote.mirror(any()));
  });
}
