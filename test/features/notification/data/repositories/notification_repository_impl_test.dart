import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:penyintas_app/features/notification/data/repositories/notification_repository_impl.dart';

class MockLocal extends Mock implements NotificationLocalDatasource {}

class MockRemote extends Mock implements NotificationRemoteDatasource {}

void main() {
  late MockLocal local;
  late MockRemote remote;
  late NotificationRepositoryImpl repo;

  const tUid = 'uid-1';
  const tToken = 'tok-1';

  setUp(() {
    local = MockLocal();
    remote = MockRemote();
    repo = NotificationRepositoryImpl(local: local, remote: remote);
  });

  group('registerToken', () {
    test('token ada → remote.registerToken dipanggil, Right(null)', () async {
      when(() => remote.getFcmToken()).thenAnswer((_) async => tToken);
      when(() => remote.registerToken(tUid, tToken)).thenAnswer((_) async {});

      final result = await repo.registerToken(tUid);

      expect(result, const Right<Failure, void>(null));
      verify(() => remote.registerToken(tUid, tToken)).called(1);
    });

    test(
      'token null → no-op Right(null), registerToken TIDAK dipanggil',
      () async {
        when(() => remote.getFcmToken()).thenAnswer((_) async => null);

        final result = await repo.registerToken(tUid);

        expect(result, const Right<Failure, void>(null));
        verifyNever(() => remote.registerToken(any(), any()));
      },
    );
  });

  group('unregisterToken', () {
    test('token ada → unregisterToken + deleteToken dipanggil', () async {
      when(() => remote.getFcmToken()).thenAnswer((_) async => tToken);
      when(() => remote.unregisterToken(tUid, tToken)).thenAnswer((_) async {});
      when(() => remote.deleteToken()).thenAnswer((_) async {});

      final result = await repo.unregisterToken(tUid);

      expect(result, const Right<Failure, void>(null));
      verify(() => remote.unregisterToken(tUid, tToken)).called(1);
      verify(() => remote.deleteToken()).called(1);
    });

    test(
      'token null → deleteToken TETAP dipanggil, unregisterToken(datasource) TIDAK dipanggil',
      () async {
        when(() => remote.getFcmToken()).thenAnswer((_) async => null);
        when(() => remote.deleteToken()).thenAnswer((_) async {});

        final result = await repo.unregisterToken(tUid);

        expect(result, const Right<Failure, void>(null));
        verify(() => remote.deleteToken()).called(1);
        verifyNever(() => remote.unregisterToken(any(), any()));
      },
    );
  });

  group('getPushEnabled', () {
    test('pass-through Right(bool)', () async {
      when(() => remote.getPushEnabled(tUid)).thenAnswer((_) async => false);
      expect(
        await repo.getPushEnabled(tUid),
        const Right<Failure, bool>(false),
      );
    });
  });

  group('setPushEnabled', () {
    test('error → Left(ServerFailure)', () async {
      when(
        () => remote.setPushEnabled(tUid, true),
      ).thenThrow(Exception('boom'));
      final result = await repo.setPushEnabled(tUid, true);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('harus Left(ServerFailure)'),
      );
    });
  });
}
