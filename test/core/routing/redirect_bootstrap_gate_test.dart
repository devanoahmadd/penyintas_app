// test/core/routing/redirect_bootstrap_gate_test.dart
// Temuan 1 / T-3: bukti redirectForAuthedUser() men-`await ensure()` SEBELUM
// guard.status() → jalur fresh-login (reinstall, tak lewat splash) tertutup.
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/routing/app_router.dart';
import 'package:penyintas_app/core/routing/bootstrap_coordinator.dart';
import 'package:penyintas_app/core/routing/onboarding_guard.dart';
import 'package:penyintas_app/core/routing/onboarding_status.dart';

class _MockCoordinator extends Mock implements BootstrapCoordinator {}

class _MockGuard extends Mock implements OnboardingGuard {}

void main() {
  final sl =
      GetIt.instance; // sama dgn `sl` injection_container — app & test berbagi
  late _MockCoordinator coordinator;
  late _MockGuard guard;
  final order = <String>[];

  setUp(() {
    order.clear();
    coordinator = _MockCoordinator();
    guard = _MockGuard();
    var seeded =
        false; // bootstrap memulihkan profil dari cloud (simulasi reinstall)
    when(() => coordinator.ensure()).thenAnswer((_) async {
      order.add('ensure');
      seeded = true; // ensure() men-seed profileCompleted=true (remote-true)
    });
    when(() => guard.status()).thenAnswer((_) async {
      order.add('status');
      // local fresh = needsProfile; hanya 'done' BILA ensure() sudah men-seed lebih dulu.
      return seeded ? OnboardingStatus.done : OnboardingStatus.needsProfile;
    });
    sl.registerSingleton<BootstrapCoordinator>(coordinator);
    sl.registerSingleton<OnboardingGuard>(guard);
  });
  tearDown(() => sl.reset());

  test(
    'redirectForAuthedUser: ensure() SEBELUM guard → BUKAN /profile-setup (Temuan 1)',
    () async {
      final result = await redirectForAuthedUser('/dashboard');
      // Urutan: ensure() harus selesai sebelum guard memutuskan. Kalau `await ensure()`
      // dihapus, guard jalan saat seeded=false → needsProfile → '/profile-setup' → GAGAL.
      expect(order, [
        'ensure',
        'status',
      ], reason: 'bootstrap harus SELESAI sebelum guard memutuskan');
      expect(
        result,
        isNot('/profile-setup'),
        reason:
            'profil dipulihkan ensure() → fresh-login tak memantul ke profile-setup',
      );
      expect(
        result,
        anyOf(isNull, '/dashboard'),
      ); // status done @ /dashboard → null
    },
  );
}
