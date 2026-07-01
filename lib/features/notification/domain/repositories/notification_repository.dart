import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';

abstract class NotificationRepository {
  Future<Either<Failure, bool>> requestPermission();
  Future<Either<Failure, void>> saveFcmToken(String uid, String token);
  Future<Either<Failure, void>> scheduleDailyReminder({
    required int hour,
    required int minute,
  });
  Future<Either<Failure, void>> cancelDailyReminder();

  /// Ambil FCM token device lalu daftarkan ke subcollection `fcmTokens` milik [uid].
  /// Bila token null (device belum mendapat token), tidak melakukan apa-apa → Right(null).
  Future<Either<Failure, void>> registerToken(String uid);

  /// Hapus FCM token device dari subcollection `fcmTokens` milik [uid],
  /// lalu selalu panggil deleteToken() untuk invalidate token di FCM.
  Future<Either<Failure, void>> unregisterToken(String uid);

  /// Ambil preferensi push notification untuk [uid] dari Firestore.
  Future<Either<Failure, bool>> getPushEnabled(String uid);

  /// Simpan preferensi push notification [enabled] untuk [uid] ke Firestore.
  Future<Either<Failure, void>> setPushEnabled(String uid, bool enabled);
}
