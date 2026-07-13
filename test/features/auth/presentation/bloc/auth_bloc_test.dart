import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/reload_user_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/wipe_local_data_usecase.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/notification/domain/usecases/register_fcm_token_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/unregister_fcm_token_usecase.dart';

// Mocks
class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockWatchAuthStateUseCase extends Mock implements WatchAuthStateUseCase {}
class MockWipeLocalDataUseCase extends Mock implements WipeLocalDataUseCase {}
class MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}
class MockGoogleSignInUseCase extends Mock implements GoogleSignInUseCase {}
class MockSendPasswordResetUseCase extends Mock implements SendPasswordResetUseCase {}
class MockRegisterFcmTokenUseCase extends Mock implements RegisterFcmTokenUseCase {}
class MockUnregisterFcmTokenUseCase extends Mock implements UnregisterFcmTokenUseCase {}
class MockReloadUserUseCase extends Mock implements ReloadUserUseCase {}

// Fallback values
class FakeSignInParams extends Fake implements SignInParams {}
class FakeSignUpParams extends Fake implements SignUpParams {}
class FakeNoParams extends Fake implements NoParams {}
class FakeDeleteAccountParams extends Fake implements DeleteAccountParams {}
class FakeSendPasswordResetParams extends Fake implements SendPasswordResetParams {}

void main() {
  late MockSignInUseCase mockSignIn;
  late MockSignUpUseCase mockSignUp;
  late MockSignOutUseCase mockSignOut;
  late MockGetCurrentUserUseCase mockGetCurrentUser;
  late MockWatchAuthStateUseCase mockWatchAuthState;
  late MockWipeLocalDataUseCase mockWipe;
  late MockDeleteAccountUseCase mockDeleteAccount;
  late MockGoogleSignInUseCase mockGoogleSignIn;
  late MockSendPasswordResetUseCase mockSendPasswordReset;
  late MockRegisterFcmTokenUseCase mockRegisterFcm;
  late MockUnregisterFcmTokenUseCase mockUnregisterFcm;
  late MockReloadUserUseCase mockReloadUser;

  final tUser = UserEntity(
    uid: 'uid-123',
    email: 'test@email.com',
    displayName: 'Tester',
    createdAt: DateTime(2025),
  );

  setUpAll(() {
    registerFallbackValue(FakeSignInParams());
    registerFallbackValue(FakeSignUpParams());
    registerFallbackValue(FakeNoParams());
    registerFallbackValue(FakeDeleteAccountParams());
    registerFallbackValue(FakeSendPasswordResetParams());
  });

  setUp(() {
    mockSignIn = MockSignInUseCase();
    mockSignUp = MockSignUpUseCase();
    mockSignOut = MockSignOutUseCase();
    mockGetCurrentUser = MockGetCurrentUserUseCase();
    mockWatchAuthState = MockWatchAuthStateUseCase();

    mockWipe = MockWipeLocalDataUseCase();
    when(() => mockWipe(any())).thenAnswer((_) async => const Right(unit));

    mockDeleteAccount = MockDeleteAccountUseCase();
    mockGoogleSignIn = MockGoogleSignInUseCase();
    mockSendPasswordReset = MockSendPasswordResetUseCase();
    mockRegisterFcm = MockRegisterFcmTokenUseCase();
    mockUnregisterFcm = MockUnregisterFcmTokenUseCase();
    mockReloadUser = MockReloadUserUseCase();
    when(() => mockRegisterFcm(any())).thenAnswer((_) async => const Right(null));
    when(() => mockUnregisterFcm(any())).thenAnswer((_) async => const Right(null));

    // Default: stream kosong agar AuthCheckRequested tidak emit state tambahan
    when(() => mockWatchAuthState()).thenAnswer((_) => const Stream.empty());
  });

  AuthBloc buildBloc() => AuthBloc(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getCurrentUser: mockGetCurrentUser,
        watchAuthState: mockWatchAuthState,
        wipeLocalData: mockWipe,
        deleteAccount: mockDeleteAccount,
        googleSignIn: mockGoogleSignIn,
        sendPasswordReset: mockSendPasswordReset,
        registerFcmToken: mockRegisterFcm,
        unregisterFcmToken: mockUnregisterFcm,
        reloadUser: mockReloadUser,
      );

  group('SignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] when sign in succeeds',
      build: buildBloc,
      act: (bloc) => bloc.add(SignInRequested(
        email: 'test@email.com',
        password: 'password123',
      )),
      setUp: () {
        when(() => mockSignIn(any()))
            .thenAnswer((_) async => Right(tUser));
      },
      expect: () => [const AuthLoading(), Authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthError] when sign in fails with wrong password',
      build: buildBloc,
      act: (bloc) => bloc.add(SignInRequested(
        email: 'test@email.com',
        password: 'wrong',
      )),
      setUp: () {
        when(() => mockSignIn(any())).thenAnswer(
          (_) async => const Left(
            AuthFailure('Email atau password salah. Coba lagi ya.'),
          ),
        );
      },
      expect: () => [
        const AuthLoading(),
        const AuthError('Email atau password salah. Coba lagi ya.'),
      ],
    );
  });

  group('SignUpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] when sign up succeeds',
      build: buildBloc,
      act: (bloc) => bloc.add(SignUpRequested(
        email: 'new@email.com',
        password: 'password123',
        name: 'Pengguna Baru',
      )),
      setUp: () {
        when(() => mockSignUp(any()))
            .thenAnswer((_) async => Right(tUser));
      },
      expect: () => [const AuthLoading(), Authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthError] when email already in use',
      build: buildBloc,
      act: (bloc) => bloc.add(SignUpRequested(
        email: 'existing@email.com',
        password: 'password123',
        name: 'User',
      )),
      setUp: () {
        when(() => mockSignUp(any())).thenAnswer(
          (_) async => const Left(
            AuthFailure('Email ini sudah terdaftar. Coba login langsung.'),
          ),
        );
      },
      expect: () => [
        const AuthLoading(),
        const AuthError('Email ini sudah terdaftar. Coba login langsung.'),
      ],
    );
  });

  group('GoogleSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'sukses → [AuthLoading, Authenticated]',
      build: () {
        when(() => mockGoogleSignIn(any()))
            .thenAnswer((_) async => Right(tUser));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [const AuthLoading(), Authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'user batal → [AuthLoading, Unauthenticated] TANPA AuthError',
      build: () {
        when(() => mockGoogleSignIn(any()))
            .thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'gagal → [AuthLoading, AuthError(pesan)]',
      build: () {
        when(() => mockGoogleSignIn(any())).thenAnswer((_) async =>
            const Left(AuthFailure('Gagal masuk dengan Google. Coba lagi ya.')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthError('Gagal masuk dengan Google. Coba lagi ya.'),
      ],
    );
  });

  group('SignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'wipe sukses → signOut → [AuthLoading, Unauthenticated]',
      build: buildBloc,
      act: (bloc) => bloc.add(const SignOutRequested()),
      setUp: () {
        when(() => mockWipe(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => mockSignOut(any()))
            .thenAnswer((_) async => const Right(null));
      },
      expect: () => [const AuthLoading(), const Unauthenticated()],
      verify: (_) {
        verify(() => mockWipe(any())).called(1);
        verify(() => mockSignOut(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'wipe gagal → AuthError, signOut TIDAK dipanggil (user tetap login)',
      build: buildBloc,
      act: (bloc) => bloc.add(const SignOutRequested()),
      setUp: () {
        when(() => mockWipe(any())).thenAnswer(
          (_) async => const Left(CacheFailure('Gagal membersihkan data.')),
        );
      },
      expect: () => [
        const AuthLoading(),
        const AuthError('Gagal membersihkan data.'),
      ],
      verify: (_) {
        verifyNever(() => mockSignOut(any()));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'wipe sukses tapi signOut gagal → AuthError',
      build: buildBloc,
      act: (bloc) => bloc.add(const SignOutRequested()),
      setUp: () {
        when(() => mockWipe(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => mockSignOut(any())).thenAnswer(
          (_) async => const Left(AuthFailure('Gagal keluar. Coba lagi.')),
        );
      },
      expect: () => [
        const AuthLoading(),
        const AuthError('Gagal keluar. Coba lagi.'),
      ],
    );
  });

  group('ForgotPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'success: emits [PasswordResetEmailSent] — AuthLoading TIDAK di-emit',
      build: buildBloc,
      setUp: () {
        when(() => mockSendPasswordReset(any()))
            .thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(
        const ForgotPasswordRequested(email: 'test@email.com'),
      ),
      expect: () => [const PasswordResetEmailSent()],
    );

    blocTest<AuthBloc, AuthState>(
      'failure: emits [AuthError] — AuthLoading TIDAK di-emit',
      build: buildBloc,
      setUp: () {
        when(() => mockSendPasswordReset(any())).thenAnswer(
          (_) async => const Left(AuthFailure('Terjadi kesalahan. Coba lagi.')),
        );
      },
      act: (bloc) => bloc.add(
        const ForgotPasswordRequested(email: 'test@email.com'),
      ),
      expect: () => [
        const AuthError('Terjadi kesalahan. Coba lagi.'),
      ],
    );
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit Authenticated when auth stream emits a user',
      build: buildBloc,
      setUp: () {
        when(() => mockWatchAuthState())
            .thenAnswer((_) => Stream.value(tUser));
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [Authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit Unauthenticated when auth stream emits null',
      build: buildBloc,
      setUp: () {
        when(() => mockWatchAuthState())
            .thenAnswer((_) => Stream.value(null));
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const Unauthenticated()],
    );
  });

  group('DeleteAccountRequested', () {
    blocTest<AuthBloc, AuthState>(
      'deleteAccount sukses → wipe sukses → signOut sukses → [DeleteAccountInProgress, Unauthenticated]',
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteAccountRequested(password: 'pw123')),
      setUp: () {
        when(() => mockDeleteAccount(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockWipe(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => mockSignOut(any()))
            .thenAnswer((_) async => const Right(null));
      },
      expect: () => [
        const DeleteAccountInProgress(),
        const Unauthenticated(),
      ],
      verify: (_) {
        verify(() => mockDeleteAccount(any())).called(1);
        verify(() => mockWipe(any())).called(1);
        verify(() => mockSignOut(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'deleteAccount gagal → [DeleteAccountInProgress, DeleteAccountFailure], wipe & signOut tidak dipanggil',
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteAccountRequested(password: 'pw123')),
      setUp: () {
        when(() => mockDeleteAccount(any())).thenAnswer(
          (_) async => const Left(AuthFailure('Password salah.')),
        );
      },
      expect: () => [
        const DeleteAccountInProgress(),
        const DeleteAccountFailure('Password salah.'),
      ],
      verify: (_) {
        verifyNever(() => mockWipe(any()));
        verifyNever(() => mockSignOut(any()));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'deleteAccount sukses tapi wipe gagal → [DeleteAccountInProgress, DeleteAccountFailure]',
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteAccountRequested(password: 'pw123')),
      setUp: () {
        when(() => mockDeleteAccount(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockWipe(any())).thenAnswer(
          (_) async => const Left(CacheFailure('Gagal membersihkan data.')),
        );
      },
      expect: () => [
        const DeleteAccountInProgress(),
        const DeleteAccountFailure('Gagal membersihkan data.'),
      ],
      verify: (_) {
        verifyNever(() => mockSignOut(any()));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'deleteAccount & wipe sukses tapi signOut gagal → [DeleteAccountInProgress, Unauthenticated]',
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteAccountRequested(password: 'pw123')),
      setUp: () {
        when(() => mockDeleteAccount(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockWipe(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => mockSignOut(any())).thenAnswer(
          (_) async => const Left(AuthFailure('Gagal keluar.')),
        );
      },
      expect: () => [
        const DeleteAccountInProgress(),
        const Unauthenticated(),
      ],
      verify: (_) {
        verify(() => mockDeleteAccount(any())).called(1);
        verify(() => mockWipe(any())).called(1);
        verify(() => mockSignOut(any())).called(1);
      },
    );
  });

  group('FCM token lifecycle (auth-driven)', () {
    blocTest<AuthBloc, AuthState>(
      'AuthCheckRequested + stream user → registerFcmToken(uid) dipanggil',
      build: buildBloc,
      setUp: () => when(() => mockWatchAuthState())
          .thenAnswer((_) => Stream.value(tUser)),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [Authenticated(tUser)],
      verify: (_) => verify(() => mockRegisterFcm('uid-123')).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'SignOut → unregisterFcmToken dipanggil SEBELUM signOut',
      build: buildBloc,
      seed: () => Authenticated(tUser),
      act: (bloc) => bloc.add(const SignOutRequested()),
      setUp: () {
        when(() => mockWipe(any())).thenAnswer((_) async => const Right(unit));
        when(() => mockSignOut(any())).thenAnswer((_) async => const Right(null));
      },
      expect: () => [const AuthLoading(), const Unauthenticated()],
      verify: (_) {
        // verifyInOrder membuktikan: unregister dipanggil SEBELUM signOut
        verifyInOrder([
          () => mockUnregisterFcm('uid-123'),
          () => mockSignOut(any()),
        ]);
      },
    );
  });

  group('AuthUserReloadRequested', () {
    final tVerifiedUser = UserEntity(
      uid: 'uid-123',
      email: 'test@email.com',
      displayName: 'Tester',
      createdAt: DateTime(2025),
      emailVerified: true,
      hasPasswordProvider: true,
    );

    blocTest<AuthBloc, AuthState>(
      'state Authenticated + reload sukses → emit Authenticated(freshUser)',
      build: () {
        when(() => mockReloadUser(any()))
            .thenAnswer((_) async => Right(tVerifiedUser));
        return buildBloc();
      },
      seed: () => Authenticated(tUser),
      act: (bloc) => bloc.add(const AuthUserReloadRequested()),
      expect: () => [Authenticated(tVerifiedUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'state bukan Authenticated → tidak melakukan apa pun',
      build: buildBloc,
      seed: () => const Unauthenticated(),
      act: (bloc) => bloc.add(const AuthUserReloadRequested()),
      expect: () => const <AuthState>[],
      verify: (_) => verifyNever(() => mockReloadUser(any())),
    );

    blocTest<AuthBloc, AuthState>(
      'reload gagal → tidak emit (status lama dipertahankan)',
      build: () {
        when(() => mockReloadUser(any()))
            .thenAnswer((_) async => const Left(UnknownFailure()));
        return buildBloc();
      },
      seed: () => Authenticated(tUser),
      act: (bloc) => bloc.add(const AuthUserReloadRequested()),
      expect: () => const <AuthState>[],
    );

    blocTest<AuthBloc, AuthState>(
      'reload return null (sesi hilang) → tidak emit',
      build: () {
        when(() => mockReloadUser(any()))
            .thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      seed: () => Authenticated(tUser),
      act: (bloc) => bloc.add(const AuthUserReloadRequested()),
      expect: () => const <AuthState>[],
    );
  });
}
