import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationPermissionGranted extends NotificationState {
  const NotificationPermissionGranted();
}

class NotificationPermissionDenied extends NotificationState {
  const NotificationPermissionDenied();
}

class NotificationScheduled extends NotificationState {
  const NotificationScheduled({required this.hour, required this.minute});
  final int hour;
  final int minute;
  @override
  List<Object?> get props => [hour, minute];
}

/// State yang diterima oleh BlocListener di app.dart untuk navigasi.
class NotificationTapHandled extends NotificationState {
  const NotificationTapHandled(this.route);
  final String route;
  @override
  List<Object?> get props => [route];
}

class NotificationCancelled extends NotificationState {
  const NotificationCancelled();
}

class NotificationError extends NotificationState {
  const NotificationError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
