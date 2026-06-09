import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/routing/onboarding_guard.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';

class MockOnboardingLocalDataSource extends Mock
    implements OnboardingLocalDataSource {}

void main() {
  late MockOnboardingLocalDataSource mockDatasource;
  late OnboardingGuard guard;

  setUp(() {
    mockDatasource = MockOnboardingLocalDataSource();
    guard = OnboardingGuard(mockDatasource);
  });

  group('isOnboardingDone', () {
    test('returns false ketika onboardingCompleted = false', () async {
      when(() => mockDatasource.isOnboardingCompleted())
          .thenAnswer((_) async => false);
      expect(await guard.isOnboardingDone(), false);
    });

    test('returns true ketika onboardingCompleted = true', () async {
      when(() => mockDatasource.isOnboardingCompleted())
          .thenAnswer((_) async => true);
      expect(await guard.isOnboardingDone(), true);
    });

    test('cache result — datasource hanya dipanggil sekali', () async {
      when(() => mockDatasource.isOnboardingCompleted())
          .thenAnswer((_) async => true);
      await guard.isOnboardingDone();
      await guard.isOnboardingDone();
      verify(() => mockDatasource.isOnboardingCompleted()).called(1);
    });

    test('resetCache memaksa re-query ke datasource', () async {
      when(() => mockDatasource.isOnboardingCompleted())
          .thenAnswer((_) async => true);
      await guard.isOnboardingDone();
      guard.resetCache();
      await guard.isOnboardingDone();
      verify(() => mockDatasource.isOnboardingCompleted()).called(2);
    });

    test('exception dari datasource di-propagate', () async {
      when(() => mockDatasource.isOnboardingCompleted())
          .thenThrow(Exception('db error'));
      expect(() => guard.isOnboardingDone(), throwsException);
    });
  });
}
