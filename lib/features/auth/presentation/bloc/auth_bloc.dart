import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/reload_user_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/wipe_local_data_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/register_fcm_token_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/unregister_fcm_token_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.getCurrentUser,
    required this.watchAuthState,
    required this.wipeLocalData,
    required this.deleteAccount,
    required this.sendPasswordReset,
    required this.registerFcmToken,
    required this.unregisterFcmToken,
    required this.reloadUser,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthUserReloadRequested>(_onAuthUserReloadRequested);
    on<_AuthStateChanged>(_onAuthStateChanged);
  }

  final SignInUseCase signIn;
  final SignUpUseCase signUp;
  final SignOutUseCase signOut;
  final GetCurrentUserUseCase getCurrentUser;
  final WatchAuthStateUseCase watchAuthState;
  final WipeLocalDataUseCase wipeLocalData;
  final DeleteAccountUseCase deleteAccount;
  final SendPasswordResetUseCase sendPasswordReset;
  final RegisterFcmTokenUseCase registerFcmToken;
  final UnregisterFcmTokenUseCase unregisterFcmToken;
  final ReloadUserUseCase reloadUser;

  StreamSubscription<UserEntity?>? _authSubscription;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authSubscription?.cancel();
    _authSubscription = watchAuthState().listen(
      (user) => add(_AuthStateChanged(user)),
    );
  }

  void _onAuthStateChanged(_AuthStateChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      // G1/K1 self-heal: daftar token tiap transisi ke Authenticated
      // (cold-launch restore, login, signup). Best-effort — jangan blok.
      unawaited(registerFcmToken(event.user!.uid));
      emit(Authenticated(event.user!));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signIn(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signUp(
      SignUpParams(
        email: event.email,
        password: event.password,
        name: event.name,
        languageCode: event.languageCode,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onAuthUserReloadRequested(
    AuthUserReloadRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;
    final result = await reloadUser(const NoParams());
    // Guard race: event beda tipe berjalan interleaved di bloc — signOut bisa
    // selesai SAAT reload in-flight. Tanpa re-check ini, emit di bawah bisa
    // "menghidupkan kembali" sesi yang sudah logout.
    if (state is! Authenticated) return;
    result.fold(
      (_) {}, // oportunistik — gagal reload = pertahankan status lama
      (user) {
        if (user != null) emit(Authenticated(user));
      },
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // G2: capture uid SAAT MASIH valid (sebelum emit AuthLoading & signOut).
    final current = state;
    final uid = current is Authenticated ? current.user.uid : null;

    emit(const AuthLoading());
    final wipeResult = await wipeLocalData(const NoParams());
    await wipeResult.fold((failure) async => emit(AuthError(failure.message)), (
      _,
    ) async {
      // G2: putus pemetaan device→akun SEBELUM signOut. Best-effort.
      if (uid != null) {
        await unregisterFcmToken(uid);
      }
      final signOutResult = await signOut(const NoParams());
      signOutResult.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(const Unauthenticated()),
      );
    });
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authSubscription?.cancel(); // prevent auth stream race
    _authSubscription = null;
    emit(const DeleteAccountInProgress());
    final result = await deleteAccount(
      DeleteAccountParams(password: event.password),
    );
    await result.fold(
      (failure) async => emit(DeleteAccountFailure(failure.message)),
      (_) async {
        // Hapus data lokal Drift
        final wipeResult = await wipeLocalData(const NoParams());
        await wipeResult.fold(
          (failure) async => emit(DeleteAccountFailure(failure.message)),
          (_) async {
            // Account already deleted — even if signOut fails, treat as logged out
            await signOut(const NoParams());
            emit(const Unauthenticated());
          },
        );
      },
    );
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // TODO: implement with google_sign_in package after configuring OAuth credentials
    emit(const AuthError('Google Sign-In belum tersedia. Gunakan email dan password.'));
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await sendPasswordReset(
      SendPasswordResetParams(email: event.email),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const PasswordResetEmailSent()),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
