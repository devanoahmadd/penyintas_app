import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;

  /// B4: status verifikasi email dari FirebaseAuth (bukan dari dokumen
  /// Firestore). Default true agar jalur lama tidak memicu banner.
  final bool emailVerified;

  /// B4: true bila akun punya provider email/password. Banner verifikasi
  /// hanya relevan untuk akun password (akun Google auto-verified).
  final bool hasPasswordProvider;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.emailVerified = true,
    this.hasPasswordProvider = false,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    createdAt,
    emailVerified,
    hasPasswordProvider,
  ];
}
