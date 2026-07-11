import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/auth/data/models/user_model.dart';
import 'package:penyintas_app/features/auth/data/services/google_sign_in_service.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    String? languageCode,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<void> reauthenticate({required String password});
  Future<void> callDeleteAccount();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification({String? languageCode});
  Future<UserModel?> reloadCurrentUser();

  /// null = user MEMBATALKAN dialog Google (bukan kegagalan).
  Future<UserModel?> signInWithGoogle();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required this.auth,
    required this.firestore,
    required this.functions,
    required this.googleSignInService,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
  final GoogleSignInService googleSignInService;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final fbUser = credential.user!;
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(
          doc,
          emailVerified: fbUser.emailVerified,
          hasPasswordProvider: _hasPasswordProvider(fbUser),
        );
      }
      // Fallback jika dokumen Firestore belum ada
      return UserModel(
        uid: uid,
        email: fbUser.email ?? email,
        displayName: fbUser.displayName ?? '',
        photoUrl: fbUser.photoURL,
        createdAt: DateTime.now(),
        emailVerified: fbUser.emailVerified,
        hasPasswordProvider: _hasPasswordProvider(fbUser),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code));
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const AuthException();
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    String? languageCode,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);

      // B4: kirim email verifikasi — non-fatal, user bisa resend dari banner.
      try {
        if (languageCode != null) await auth.setLanguageCode(languageCode);
        await credential.user!.sendEmailVerification();
      } catch (e, s) {
        try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      }

      final model = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: name,
        createdAt: DateTime.now(),
        emailVerified: false,       // baru register — pasti belum verifikasi
        hasPasswordProvider: true,  // jalur ini selalu email/password
      );

      await firestore
          .collection('users')
          .doc(model.uid)
          .set(model.toFirestore());

      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code));
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const AuthException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const AuthException('Gagal keluar. Coba lagi.');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(
          doc,
          emailVerified: user.emailVerified,
          hasPasswordProvider: _hasPasswordProvider(user),
        );
      }
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        emailVerified: user.emailVerified,
        hasPasswordProvider: _hasPasswordProvider(user),
      );
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const ServerException();
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc =
            await firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromFirestore(
            doc,
            emailVerified: user.emailVerified,
            hasPasswordProvider: _hasPasswordProvider(user),
          );
        }
      } catch (_) {}
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        emailVerified: user.emailVerified,
        hasPasswordProvider: _hasPasswordProvider(user),
      );
    });
  }

  @override
  Future<void> reauthenticate({required String password}) async {
    final user = auth.currentUser;
    if (user == null) {
      throw const AuthException('Sesi tidak ditemukan. Login ulang.');
    }
    try {
      final email = user.email;
      if (email == null) {
        throw const AuthException('Akun ini tidak mendukung konfirmasi password. Hubungi dukungan.');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code));
    }
  }

  @override
  Future<void> callDeleteAccount() async {
    try {
      await functions.httpsCallable('deleteAccount').call();
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(e.message ?? 'Gagal menghapus akun.');
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const AuthException('Gagal menghapus akun.');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // user-not-found: jangan bocorkan. Return normal = same UX as success.
      // Firebase Auth tidak expose info apakah email terdaftar — kita match itu.
      if (e.code == 'user-not-found') return;
      throw AuthException(_mapFirebaseCode(e.code));
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const AuthException();
    }
  }

  @override
  Future<void> sendEmailVerification({String? languageCode}) async {
    final user = auth.currentUser;
    if (user == null) {
      throw const AuthException('Sesi tidak ditemukan. Login ulang.');
    }
    try {
      if (languageCode != null) await auth.setLanguageCode(languageCode);
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code));
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const AuthException();
    }
  }

  @override
  Future<UserModel?> reloadCurrentUser() async {
    final user = auth.currentUser;
    if (user == null) return null;
    try {
      await user.reload();
    } catch (_) {
      return null; // reload oportunistik — gagal = pertahankan status lama
    }
    final fresh = auth.currentUser;
    if (fresh == null) return null;
    try {
      final doc = await firestore.collection('users').doc(fresh.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(
          doc,
          emailVerified: fresh.emailVerified,
          hasPasswordProvider: _hasPasswordProvider(fresh),
        );
      }
    } catch (_) {}
    return UserModel(
      uid: fresh.uid,
      email: fresh.email ?? '',
      displayName: fresh.displayName ?? '',
      photoUrl: fresh.photoURL,
      createdAt: DateTime.now(),
      emailVerified: fresh.emailVerified,
      hasPasswordProvider: _hasPasswordProvider(fresh),
    );
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final String? idToken;
    try {
      idToken = await googleSignInService.getIdToken();
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const AuthException('Gagal masuk dengan Google. Coba lagi ya.');
    }
    if (idToken == null) return null; // user membatalkan dialog — bukan error

    try {
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user!;

      final docRef = firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        return UserModel.fromFirestore(
          doc,
          emailVerified: user.emailVerified,
          hasPasswordProvider: _hasPasswordProvider(user),
        );
      }

      // User Google baru — buat dokumen profil (pola signUp)
      final model = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        emailVerified: user.emailVerified,
        hasPasswordProvider: _hasPasswordProvider(user),
      );
      await docRef.set(model.toFirestore());
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code));
    } catch (e, s) {
      try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      throw const AuthException('Gagal masuk dengan Google. Coba lagi ya.');
    }
  }

  // Deteksi apakah akun punya provider email/password (bukan hanya Google).
  static bool _hasPasswordProvider(User user) =>
      user.providerData.any((p) => p.providerId == 'password');

  static String _mapFirebaseCode(String code) => switch (code) {
        'email-already-in-use' =>
          'Email ini sudah terdaftar. Coba masuk langsung, atau pakai tombol Google.',
        // user-not-found digabung agar tidak bocorkan info email terdaftar
        // (anti user-enumeration). Pesan signup 'email-already-in-use' di bawah
        // dipertahankan karena UX-nya memang perlu memberi tahu — kini juga
        // menyertakan alternatif tombol Google.
        'wrong-password' || 'invalid-credential' || 'user-not-found' =>
          'Email atau password salah. Coba lagi ya.',
        'invalid-email' => 'Format email tidak valid.',
        'weak-password' => 'Password terlalu lemah. Gunakan minimal 8 karakter.',
        'too-many-requests' =>
          'Terlalu banyak percobaan. Tunggu sebentar ya.',
        'network-request-failed' =>
          'Tidak ada koneksi. Periksa internet kamu.',
        'user-disabled' => 'Akun ini dinonaktifkan. Hubungi dukungan.',
        'requires-recent-login' => 'Sesi kamu sudah habis. Login ulang untuk melanjutkan.',
        _ => 'Terjadi kesalahan. Coba lagi.',
      };
}
