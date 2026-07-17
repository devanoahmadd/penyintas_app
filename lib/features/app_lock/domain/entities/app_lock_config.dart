import 'package:equatable/equatable.dart';

/// Konfigurasi App Lock — device-local, tidak pernah disinkron ke Firestore.
///
/// `hasPin` hanya menandakan *ada tidaknya* PIN. Hash PIN (salted SHA-256,
/// lihat `PinHasher`) tak pernah keluar dari lapisan repository — entity ini
/// sengaja tidak mengekspos hash demi keamanan.
class AppLockConfig extends Equatable {
  const AppLockConfig({
    required this.enabled,
    required this.hasPin,
    required this.biometricEnabled,
    this.ownerUid,
  });

  final bool enabled;
  final bool hasPin;
  final bool biometricEnabled;
  final String? ownerUid;

  @override
  List<Object?> get props => [enabled, hasPin, biometricEnabled, ownerUid];
}
