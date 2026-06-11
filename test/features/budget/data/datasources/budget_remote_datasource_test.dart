import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:penyintas_app/features/budget/data/models/budget_settings_model.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late BudgetRemoteDatasourceImpl datasource;

  const tUid = 'uid-test';

  final tModel = BudgetSettingsModel(
    monthlyIncome: 3000000,
    paymentDate: 25,
    otherFixedExpense: 800000,
    emergencyFundPct: 0.10,
    createdAt: DateTime(2026, 5, 8),
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn(tUid);
    when(() => auth.currentUser).thenReturn(user);
    datasource = BudgetRemoteDatasourceImpl(auth: auth, firestore: firestore);
  });

  group('getBudgetSettings', () {
    test('returns null jika dokumen tidak ada', () async {
      final result = await datasource.getBudgetSettings();
      expect(result, isNull);
    });

    test('returns null jika uid null', () async {
      when(() => auth.currentUser).thenReturn(null);
      final result = await datasource.getBudgetSettings();
      expect(result, isNull);
    });

    test('returns model jika dokumen ada', () async {
      await firestore
          .collection('users')
          .doc(tUid)
          .collection('budget_settings')
          .doc('current')
          .set(tModel.toFirestore());

      final result = await datasource.getBudgetSettings();

      expect(result, isNotNull);
      expect(result!.monthlyIncome, 3000000);
      expect(result.paymentDate, 25);
      expect(result.otherFixedExpense, 800000);
      expect(result.emergencyFundPct, 0.10);
      expect(result.createdAt, DateTime(2026, 5, 8));
    });
  });
}
