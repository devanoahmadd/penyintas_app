import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/auth/presentation/pages/splash_page.dart';

void main() {
  test('pending route ada → pakai route itu', () {
    expect(resolveSplashRoute('/budget'), '/budget');
  });
  test('pending route null → fallback /dashboard', () {
    expect(resolveSplashRoute(null), '/dashboard');
  });
}
