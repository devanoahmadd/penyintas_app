import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:penyintas_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource remote;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: remote);
  });

  group('deleteAccount', () {
    test('password terisi → reauthenticate(password) lalu callDeleteAccount',
        () async {
      when(() => remote.reauthenticate(password: any(named: 'password')))
          .thenAnswer((_) async {});
      when(() => remote.callDeleteAccount()).thenAnswer((_) async {});

      final result = await repository.deleteAccount(password: 'rahasia1');

      expect(result.isRight(), isTrue);
      verify(() => remote.reauthenticate(password: 'rahasia1')).called(1);
      verify(() => remote.callDeleteAccount()).called(1);
      verifyNever(() => remote.reauthenticateWithGoogle());
    });

    test('password null → reauthenticateWithGoogle lalu callDeleteAccount',
        () async {
      when(() => remote.reauthenticateWithGoogle())
          .thenAnswer((_) async => true);
      when(() => remote.callDeleteAccount()).thenAnswer((_) async {});

      final result = await repository.deleteAccount(password: null);

      expect(result.isRight(), isTrue);
      verify(() => remote.reauthenticateWithGoogle()).called(1);
      verify(() => remote.callDeleteAccount()).called(1);
      verifyNever(
          () => remote.reauthenticate(password: any(named: 'password')));
    });

    test('jalur Google dibatalkan → Left AuthFailure, akun TIDAK dihapus',
        () async {
      when(() => remote.reauthenticateWithGoogle())
          .thenAnswer((_) async => false);

      final result = await repository.deleteAccount(password: null);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('seharusnya Left'),
      );
      verifyNever(() => remote.callDeleteAccount());
    });

    test('AuthException dari reauth → Left AuthFailure', () async {
      when(() => remote.reauthenticateWithGoogle())
          .thenThrow(const AuthException('Sesi tidak ditemukan. Login ulang.'));

      final result = await repository.deleteAccount(password: null);

      expect(result.isLeft(), isTrue);
      verifyNever(() => remote.callDeleteAccount());
    });
  });
}
