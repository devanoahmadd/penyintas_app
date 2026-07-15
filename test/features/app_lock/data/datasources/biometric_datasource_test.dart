import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/app_lock/data/datasources/biometric_datasource.dart';

class _MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  late _MockLocalAuth auth;
  late BiometricDataSourceImpl ds;

  // Diperlukan mocktail: any()/captureAny() pada parameter bertipe
  // AuthenticationOptions (non-nullable) butuh fallback value terdaftar,
  // jika tidak dilempar Bad state saat evaluasi matcher.
  setUpAll(() {
    registerFallbackValue(const AuthenticationOptions());
  });

  setUp(() {
    auth = _MockLocalAuth();
    ds = BiometricDataSourceImpl(auth);
  });

  test('isAvailable true bila supported + canCheck + ada biometrik enrolled', () async {
    when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
    when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => auth.getAvailableBiometrics())
        .thenAnswer((_) async => [BiometricType.fingerprint]);
    expect(await ds.isAvailable(), isTrue);
  });

  test('isAvailable false bila tak ada biometrik enrolled', () async {
    when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
    when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => auth.getAvailableBiometrics()).thenAnswer((_) async => []);
    expect(await ds.isAvailable(), isFalse);
  });

  test('isAvailable false bila exception (fail-safe)', () async {
    when(() => auth.isDeviceSupported()).thenThrow(Exception('x'));
    expect(await ds.isAvailable(), isFalse);
  });

  test('authenticate memakai biometricOnly + stickyAuth', () async {
    when(() => auth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => true);
    final ok = await ds.authenticate('buka');
    expect(ok, isTrue);
    final captured = verify(() => auth.authenticate(
          localizedReason: 'buka',
          options: captureAny(named: 'options'),
        )).captured.single as AuthenticationOptions;
    expect(captured.biometricOnly, isTrue);
    expect(captured.stickyAuth, isTrue);
  });
}
