import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/auth/data/datasources/auth_remote_datasource.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUserInfo extends Mock implements UserInfo {}
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late MockFirebaseFunctions functions;
  late AuthRemoteDataSourceImpl datasource;
  late MockUser user;
  late MockUserCredential credential;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
    functions = MockFirebaseFunctions();
    datasource = AuthRemoteDataSourceImpl(
      auth: auth,
      firestore: firestore,
      functions: functions,
    );
    user = MockUser();
    credential = MockUserCredential();

    when(() => credential.user).thenReturn(user);
    when(() => user.uid).thenReturn('uid-1');
    when(() => user.email).thenReturn('a@b.com');
    when(() => user.displayName).thenReturn('Andi');
    when(() => user.photoURL).thenReturn(null);
    when(() => user.emailVerified).thenReturn(false);
    when(() => user.providerData).thenReturn(const []);
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    when(() => auth.setLanguageCode(any())).thenAnswer((_) async {});
  });

  group('signUp — B4 kirim email verifikasi', () {
    setUp(() {
      when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => credential);
    });

    test('memanggil sendEmailVerification setelah akun dibuat', () async {
      await datasource.signUp(
          email: 'a@b.com', password: 'rahasia123', name: 'Andi');
      verify(() => user.sendEmailVerification()).called(1);
    });

    test('set languageCode sebelum kirim bila diberikan', () async {
      await datasource.signUp(
          email: 'a@b.com',
          password: 'rahasia123',
          name: 'Andi',
          languageCode: 'id');
      verify(() => auth.setLanguageCode('id')).called(1);
    });

    test('gagal kirim verifikasi TIDAK menggagalkan register (non-fatal)', () async {
      when(() => user.sendEmailVerification())
          .thenThrow(FirebaseAuthException(code: 'too-many-requests'));
      final model = await datasource.signUp(
          email: 'a@b.com', password: 'rahasia123', name: 'Andi');
      expect(model.uid, 'uid-1');
    });

    test('model hasil signUp: emailVerified false, hasPasswordProvider true', () async {
      final model = await datasource.signUp(
          email: 'a@b.com', password: 'rahasia123', name: 'Andi');
      expect(model.emailVerified, isFalse);
      expect(model.hasPasswordProvider, isTrue);
    });
  });

  group('signIn — flag dari FirebaseAuth User', () {
    test('flag terisi dari credential.user (fallback tanpa doc Firestore)', () async {
      final pwdInfo = MockUserInfo();
      when(() => pwdInfo.providerId).thenReturn('password');
      when(() => user.providerData).thenReturn([pwdInfo]);
      when(() => user.emailVerified).thenReturn(false);
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => credential);

      final model =
          await datasource.signIn(email: 'a@b.com', password: 'rahasia123');
      expect(model.emailVerified, isFalse);
      expect(model.hasPasswordProvider, isTrue);
    });

    test('flag juga terisi saat dokumen Firestore ADA', () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@b.com',
        'displayName': 'Andi',
        'createdAt': DateTime(2026),
      });
      final pwdInfo = MockUserInfo();
      when(() => pwdInfo.providerId).thenReturn('password');
      when(() => user.providerData).thenReturn([pwdInfo]);
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => credential);

      final model =
          await datasource.signIn(email: 'a@b.com', password: 'rahasia123');
      expect(model.hasPasswordProvider, isTrue);
      expect(model.emailVerified, isFalse);
    });
  });
}
