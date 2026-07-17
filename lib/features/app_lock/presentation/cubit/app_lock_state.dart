import 'package:equatable/equatable.dart';

/// State machine App Lock: unknown → disabled → unlocked → locked.
///
/// `AppLockUnknown` adalah shade fail-closed saat konfigurasi/uid belum
/// resolve — dipakai gate untuk menutup layar sampai state pasti diketahui.
sealed class AppLockState extends Equatable {
  const AppLockState();
  @override
  List<Object?> get props => [];
}

/// Belum diketahui apakah lock aktif — gate menampilkan shade (fail-closed).
final class AppLockUnknown extends AppLockState {
  const AppLockUnknown();
}

/// App Lock tidak aktif — gate menampilkan child (isi aplikasi).
final class AppLockDisabled extends AppLockState {
  const AppLockDisabled();
}

/// App Lock aktif dan sesi sudah terbuka.
///
/// `obscured` dipakai Task 8 (grace/lifecycle) untuk menutup layar dengan
/// shade tanpa mengembalikan ke Locked penuh — di luar scope Task 7.
final class AppLockUnlocked extends AppLockState {
  const AppLockUnlocked({this.obscured = false});
  final bool obscured;
  @override
  List<Object?> get props => [obscured];
}

/// App Lock aktif dan sesi terkunci — user harus submit PIN/biometrik.
final class AppLockLocked extends AppLockState {
  const AppLockLocked({
    this.failedAttempts = 0,
    this.lockedUntilMs = 0,
    this.biometricAvailable = false,
    this.authInProgress = false,
  });
  final int failedAttempts;
  final int lockedUntilMs;
  final bool biometricAvailable;
  final bool authInProgress;

  AppLockLocked copyWith({
    int? failedAttempts,
    int? lockedUntilMs,
    bool? biometricAvailable,
    bool? authInProgress,
  }) => AppLockLocked(
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntilMs: lockedUntilMs ?? this.lockedUntilMs,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    authInProgress: authInProgress ?? this.authInProgress,
  );

  @override
  List<Object?> get props => [
    failedAttempts,
    lockedUntilMs,
    biometricAvailable,
    authInProgress,
  ];
}
