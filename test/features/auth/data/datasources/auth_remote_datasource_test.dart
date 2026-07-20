import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:penyintas_app/features/auth/data/services/google_sign_in_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUserInfo extends Mock implements UserInfo {}

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockGoogleSignInService extends Mock implements GoogleSignInService {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late MockFirebaseFunctions functions;
  late MockGoogleSignInService googleService;
  late AuthRemoteDataSourceImpl datasource;
  late MockUser user;
  late MockUserCredential credential;

  setUpAll(() => registerFallbackValue(FakeAuthCredential()));

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
    functions = MockFirebaseFunctions();
    googleService = MockGoogleSignInService();
    datasource = AuthRemoteDataSourceImpl(
      auth: auth,
      firestore: firestore,
      functions: functions,
      googleSignInService: googleService,
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
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);
    });

    test('memanggil sendEmailVerification setelah akun dibuat', () async {
      await datasource.signUp(
        email: 'a@b.com',
        password: 'rahasia123',
        name: 'Andi',
      );
      verify(() => user.sendEmailVerification()).called(1);
    });

    test('set languageCode sebelum kirim bila diberikan', () async {
      await datasource.signUp(
        email: 'a@b.com',
        password: 'rahasia123',
        name: 'Andi',
        languageCode: 'id',
      );
      verify(() => auth.setLanguageCode('id')).called(1);
    });

    test(
      'gagal kirim verifikasi TIDAK menggagalkan register (non-fatal)',
      () async {
        when(
          () => user.sendEmailVerification(),
        ).thenThrow(FirebaseAuthException(code: 'too-many-requests'));
        final model = await datasource.signUp(
          email: 'a@b.com',
          password: 'rahasia123',
          name: 'Andi',
        );
        expect(model.uid, 'uid-1');
      },
    );

    test(
      'model hasil signUp: emailVerified false, hasPasswordProvider true',
      () async {
        final model = await datasource.signUp(
          email: 'a@b.com',
          password: 'rahasia123',
          name: 'Andi',
        );
        expect(model.emailVerified, isFalse);
        expect(model.hasPasswordProvider, isTrue);
      },
    );
  });

  group('signIn — flag dari FirebaseAuth User', () {
    test(
      'flag terisi dari credential.user (fallback tanpa doc Firestore)',
      () async {
        final pwdInfo = MockUserInfo();
        when(() => pwdInfo.providerId).thenReturn('password');
        when(() => user.providerData).thenReturn([pwdInfo]);
        when(() => user.emailVerified).thenReturn(false);
        when(
          () => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => credential);

        final model = await datasource.signIn(
          email: 'a@b.com',
          password: 'rahasia123',
        );
        expect(model.emailVerified, isFalse);
        expect(model.hasPasswordProvider, isTrue);
      },
    );

    test('flag juga terisi saat dokumen Firestore ADA', () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@b.com',
        'displayName': 'Andi',
        'createdAt': DateTime(2026),
      });
      final pwdInfo = MockUserInfo();
      when(() => pwdInfo.providerId).thenReturn('password');
      when(() => user.providerData).thenReturn([pwdInfo]);
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      final model = await datasource.signIn(
        email: 'a@b.com',
        password: 'rahasia123',
      );
      expect(model.hasPasswordProvider, isTrue);
      expect(model.emailVerified, isFalse);
    });
  });

  group('sendEmailVerification (resend dari banner)', () {
    test('tanpa sesi → AuthException', () async {
      when(() => auth.currentUser).thenReturn(null);
      await expectLater(
        datasource.sendEmailVerification(),
        throwsA(isA<AuthException>()),
      );
    });

    test('dengan sesi → kirim + set languageCode', () async {
      when(() => auth.currentUser).thenReturn(user);
      await datasource.sendEmailVerification(languageCode: 'id');
      verify(() => auth.setLanguageCode('id')).called(1);
      verify(() => user.sendEmailVerification()).called(1);
    });

    test('too-many-requests → AuthException dengan pesan tenang', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(
        () => user.sendEmailVerification(),
      ).thenThrow(FirebaseAuthException(code: 'too-many-requests'));
      await expectLater(
        datasource.sendEmailVerification(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('reloadCurrentUser (refresh status verified)', () {
    test('tanpa sesi → null', () async {
      when(() => auth.currentUser).thenReturn(null);
      expect(await datasource.reloadCurrentUser(), isNull);
    });

    test('reload gagal (offline) → null, tanpa throw', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(
        () => user.reload(),
      ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      expect(await datasource.reloadCurrentUser(), isNull);
    });

    test('sukses → model dengan flag terbaru', () async {
      final pwdInfo = MockUserInfo();
      when(() => pwdInfo.providerId).thenReturn('password');
      when(() => user.providerData).thenReturn([pwdInfo]);
      when(() => user.emailVerified).thenReturn(true); // baru saja verifikasi
      when(() => user.reload()).thenAnswer((_) async {});
      when(() => auth.currentUser).thenReturn(user);

      final model = await datasource.reloadCurrentUser();
      expect(model, isNotNull);
      expect(model!.emailVerified, isTrue);
      expect(model.hasPasswordProvider, isTrue);
    });
  });

  group('signInWithGoogle', () {
    setUp(() {
      when(
        () => auth.signInWithCredential(any()),
      ).thenAnswer((_) async => credential);
      when(() => user.emailVerified).thenReturn(true);
    });

    setUpAll(() {
      registerFallbackValue(GoogleAuthProvider.credential(idToken: 'x'));
    });

    test('user batal (service return null) → null tanpa error', () async {
      when(() => googleService.getIdToken()).thenAnswer((_) async => null);
      expect(await datasource.signInWithGoogle(), isNull);
      verifyNever(() => auth.signInWithCredential(any()));
    });

    test('user baru → dokumen users/{uid} dibuat + model kembali', () async {
      when(() => googleService.getIdToken()).thenAnswer((_) async => 'token-1');

      final model = await datasource.signInWithGoogle();

      expect(model, isNotNull);
      expect(model!.uid, 'uid-1');
      expect(model.emailVerified, isTrue);
      expect(model.hasPasswordProvider, isFalse);
      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['email'], 'a@b.com');
    });

    test('user existing → baca dokumen, TIDAK menimpa createdAt', () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@b.com',
        'displayName': 'Andi Lama',
        'createdAt': DateTime(2025),
      });
      when(() => googleService.getIdToken()).thenAnswer((_) async => 'token-1');

      final model = await datasource.signInWithGoogle();

      expect(model!.displayName, 'Andi Lama');
      expect(model.createdAt.year, 2025);
    });

    test('kegagalan service (bukan batal) → AuthException', () async {
      when(
        () => googleService.getIdToken(),
      ).thenThrow(Exception('play services'));
      await expectLater(
        datasource.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test(
      'email-already-in-use saat signUp → copy mengarahkan ke Google (spec §7)',
      () async {
        when(
          () => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
        await expectLater(
          datasource.signUp(
            email: 'a@b.com',
            password: 'rahasia123',
            name: 'Andi',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('Google'),
            ),
          ),
        );
      },
    );
  });

  group('reauthenticateWithGoogle', () {
    test('user batal (idToken null) → return false tanpa panggil reauth',
        () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => googleService.getIdToken()).thenAnswer((_) async => null);

      final result = await datasource.reauthenticateWithGoogle();

      expect(result, isFalse);
      verifyNever(() => user.reauthenticateWithCredential(any()));
    });

    test('sukses → reauthenticateWithCredential dipanggil, return true',
        () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => googleService.getIdToken())
          .thenAnswer((_) async => 'id-token-1');
      when(() => user.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => credential);

      final result = await datasource.reauthenticateWithGoogle();

      expect(result, isTrue);
      verify(() => user.reauthenticateWithCredential(any())).called(1);
    });

    test('user-mismatch → AuthException pesan akun Google berbeda', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => googleService.getIdToken())
          .thenAnswer((_) async => 'id-token-1');
      when(() => user.reauthenticateWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-mismatch'));

      expect(
        () => datasource.reauthenticateWithGoogle(),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('berbeda'),
        )),
      );
    });

    test('belum login → AuthException', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(
        () => datasource.reauthenticateWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('getIdToken melempar exception → AuthException', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => googleService.getIdToken())
          .thenThrow(Exception('play services'));

      expect(
        () => datasource.reauthenticateWithGoogle(),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Gagal menghubungi Google'),
        )),
      );
    });
  });
}
