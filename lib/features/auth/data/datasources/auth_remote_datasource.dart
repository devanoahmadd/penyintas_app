import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required this.auth,
    required this.firestore,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

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
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      // Fallback jika dokumen Firestore belum ada
      return UserModel(
        uid: uid,
        email: credential.user!.email ?? email,
        displayName: credential.user!.displayName ?? '',
        photoUrl: credential.user!.photoURL,
        createdAt: DateTime.now(),
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
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);

      final model = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: name,
        createdAt: DateTime.now(),
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
      if (doc.exists) return UserModel.fromFirestore(doc);
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
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
        if (doc.exists) return UserModel.fromFirestore(doc);
      } catch (_) {}
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
    });
  }

  static String _mapFirebaseCode(String code) => switch (code) {
        'email-already-in-use' =>
          'Email ini sudah terdaftar. Coba login langsung.',
        'wrong-password' || 'invalid-credential' =>
          'Email atau password salah. Coba lagi ya.',
        'user-not-found' => 'Email belum terdaftar. Yuk daftar dulu.',
        'invalid-email' => 'Format email tidak valid.',
        'weak-password' => 'Password terlalu lemah. Gunakan minimal 8 karakter.',
        'too-many-requests' =>
          'Terlalu banyak percobaan. Tunggu sebentar ya.',
        'network-request-failed' =>
          'Tidak ada koneksi. Periksa internet kamu.',
        'user-disabled' => 'Akun ini dinonaktifkan. Hubungi dukungan.',
        _ => 'Terjadi kesalahan. Coba lagi.',
      };
}
