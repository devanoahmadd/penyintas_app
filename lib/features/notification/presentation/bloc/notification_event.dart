import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

/// Dipanggil saat app pertama kali start — inisialisasi plugin & listen token.
class InitNotification extends NotificationEvent {
  const InitNotification();
}

/// Dipanggil setelah onboarding selesai untuk meminta izin notifikasi.
class RequestPermission extends NotificationEvent {
  const RequestPermission();
}

/// FCM token baru tersedia (refresh).
class FcmTokenRefreshed extends NotificationEvent {
  const FcmTokenRefreshed(this.token);
  final String token;
  @override
  List<Object?> get props => [token];
}

/// User mengetuk notifikasi — navigasi ke route tertentu.
class NotificationTapped extends NotificationEvent {
  const NotificationTapped(this.payload);
  final String? payload;
  @override
  List<Object?> get props => [payload];
}

/// Jadwalkan pengingat harian pada jam tertentu.
class ScheduleDailyReminder extends NotificationEvent {
  const ScheduleDailyReminder({required this.hour, required this.minute});
  final int hour;
  final int minute;
  @override
  List<Object?> get props => [hour, minute];
}

/// Batalkan pengingat harian.
class CancelDailyReminder extends NotificationEvent {
  const CancelDailyReminder();
}
