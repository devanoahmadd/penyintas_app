part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  const SignInRequested({required this.email, required this.password});

  @override
  // password dikecualikan dari props agar tidak bocor lewat toString()
  // jika BlocObserver logging ditambahkan kelak.
  List<Object> get props => [email];
}

final class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  const SignUpRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  // password dikecualikan dari props — lihat komentar di SignInRequested.
  List<Object> get props => [email, name];
}

final class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

final class _AuthStateChanged extends AuthEvent {
  final UserEntity? user;
  const _AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}
