import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_remote_datasource.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  setUpAll(() => registerFallbackValue(StackTrace.empty));
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirebaseCrashlytics mockCrashlytics;
  late OnboardingRemoteDataSourceImpl datasource;

  const tUid = 'uid-test-123';

  final tSettings = BudgetSettingsEntity(
    monthlyIncome: 3000000,
    paymentDate: 25,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 1, 1),
    rentExpense: 1000000,
    utilitiesExpense: 150000,
    internetExpense: 100000,
    phoneExpense: 50000,
    otherFixedExpense: 0,
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockCrashlytics = MockFirebaseCrashlytics();

    when(() => mockUser.uid).thenReturn(tUid);
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    datasource = OnboardingRemoteDataSourceImpl(
      firestore: fakeFirestore,
      auth: mockAuth,
      crashlytics: mockCrashlytics,
    );
  });

  group('saveBudgetSettings — happy path', () {
    test('menulis dokumen ke Firestore', () async {
      await datasource.saveBudgetSettings(tSettings);

      final doc = await fakeFirestore
          .collection('users')
          .doc(tUid)
          .collection('budget_settings')
          .doc('current')
          .get();

      expect(doc.exists, isTrue);
    });

    test('field monthlyIncome dan paymentDate tersimpan benar', () async {
      await datasource.saveBudgetSettings(tSettings);

      final doc = await fakeFirestore
          .collection('users')
          .doc(tUid)
          .collection('budget_settings')
          .doc('current')
          .get();
      final data = doc.data()!;

      expect(data['monthlyIncome'], 3000000);
      expect(data['paymentDate'], 25);
    });

    test('semua breakdown expense tersimpan benar', () async {
      await datasource.saveBudgetSettings(tSettings);

      final doc = await fakeFirestore
          .collection('users')
          .doc(tUid)
          .collection('budget_settings')
          .doc('current')
          .get();
      final data = doc.data()!;

      expect(data['rentExpense'], 1000000);
      expect(data['utilitiesExpense'], 150000);
      expect(data['internetExpense'], 100000);
      expect(data['phoneExpense'], 50000);
      expect(data['otherFixedExpense'], 0);
      expect(data['emergencyFundPct'], 0.10);
    });
  });

  group('saveBudgetSettings — error path', () {
    test('uid null → throws AuthException', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(
        () => datasource.saveBudgetSettings(tSettings),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('getBudgetSettings', () {
    test('returns null jika document tidak ada', () async {
      final result = await datasource.getBudgetSettings();
      expect(result, isNull);
    });

    test('returns null jika uid null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final result = await datasource.getBudgetSettings();
      expect(result, isNull);
    });

    test('returns model jika document ada', () async {
      await datasource.saveBudgetSettings(tSettings);
      final result = await datasource.getBudgetSettings();

      expect(result, isNotNull);
      expect(result!.monthlyIncome, 3000000);
      expect(result.paymentDate, 25);
    });

    test('model expense fields sesuai dengan yang disimpan', () async {
      await datasource.saveBudgetSettings(tSettings);
      final result = await datasource.getBudgetSettings();

      expect(result!.rentExpense, 1000000);
      expect(result.utilitiesExpense, 150000);
      expect(result.internetExpense, 100000);
      expect(result.phoneExpense, 50000);
      expect(result.otherFixedExpense, 0);
    });
  });

  group('error path Firestore → recordError + ServerException (#231)', () {
    late MockFirebaseFirestore throwingFirestore;
    late OnboardingRemoteDataSourceImpl dsThrow;

    setUp(() {
      throwingFirestore = MockFirebaseFirestore();
      when(() => throwingFirestore.collection(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', message: 'simulated'),
      );
      when(() => mockCrashlytics.recordError(any(), any()))
          .thenAnswer((_) async {});
      dsThrow = OnboardingRemoteDataSourceImpl(
        firestore: throwingFirestore,
        auth: mockAuth, // currentUser = mockUser (uid terisi) dari setUp utama
        crashlytics: mockCrashlytics,
      );
    });

    test('saveBudgetSettings: error → recordError dipanggil + throw ServerException',
        () async {
      await expectLater(
        () => dsThrow.saveBudgetSettings(tSettings),
        throwsA(isA<ServerException>()),
      );
      verify(() => mockCrashlytics.recordError(any(), any())).called(1);
    });

    test('getBudgetSettings: error → recordError dipanggil + throw ServerException',
        () async {
      await expectLater(
        () => dsThrow.getBudgetSettings(),
        throwsA(isA<ServerException>()),
      );
      verify(() => mockCrashlytics.recordError(any(), any())).called(1);
    });
  });
}
