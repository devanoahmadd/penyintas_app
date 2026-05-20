import 'dart:async';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/notification/domain/usecases/cancel_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/request_permission_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/save_fcm_token_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/schedule_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required RequestPermissionUseCase requestPermission,
    required SaveFcmTokenUseCase saveFcmToken,
    required ScheduleDailyReminderUseCase scheduleDailyReminder,
    required CancelDailyReminderUseCase cancelDailyReminder,
    required FirebaseMessaging messaging,
    required FirebaseAuth auth,
    required NotificationLocalDatasource local,
    required AppDatabase db,
  })  : _requestPermission = requestPermission,
        _saveFcmToken = saveFcmToken,
        _scheduleDailyReminder = scheduleDailyReminder,
        _cancelDailyReminder = cancelDailyReminder,
        _messaging = messaging,
        _auth = auth,
        _local = local,
        _db = db,
        super(const NotificationInitial()) {
    on<InitNotification>(_onInit);
    on<RequestPermission>(_onRequestPermission);
    on<FcmTokenRefreshed>(_onTokenRefreshed);
    on<NotificationTapped>(_onTapped);
    on<ScheduleDailyReminder>(_onSchedule);
    on<CancelDailyReminder>(_onCancel);
  }

  final RequestPermissionUseCase _requestPermission;
  final SaveFcmTokenUseCase _saveFcmToken;
  final ScheduleDailyReminderUseCase _scheduleDailyReminder;
  final CancelDailyReminderUseCase _cancelDailyReminder;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final NotificationLocalDatasource _local;
  final AppDatabase _db;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  Future<void> _onInit(
    InitNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _local.initialize(onTap: (p) => add(NotificationTapped(p)));

      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
        add(FcmTokenRefreshed(token));
      });

      _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
        final route = message.data['route'] as String?;
        if (route != null) add(NotificationTapped(route));
      });

      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final route = message.data['route'] as String?;
        if (route != null) add(NotificationTapped(route));
      });

      final settings = await (_db.select(_db.appSettings)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      if (settings != null && settings.reminderEnabled) {
        await _local.scheduleDailyReminder(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
    }
  }

  Future<void> _onRequestPermission(
    RequestPermission event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _requestPermission();
    await result.fold(
      (failure) async => emit(NotificationError(failure.message)),
      (granted) async {
        if (granted) {
          emit(const NotificationPermissionGranted());
          final uid = _auth.currentUser?.uid;
          if (uid != null) {
            try {
              // iOS: give the native permission dialog time to dismiss before
              // requesting an FCM token, which can trigger a second dialog.
              await Future.delayed(const Duration(milliseconds: 300));
              final token = await _messaging.getToken();
              if (token != null) await _saveFcmToken(uid, token);
            } catch (e, s) {
              FirebaseCrashlytics.instance.recordError(e, s);
            }
          }
        } else {
          emit(const NotificationPermissionDenied());
        }
      },
    );
  }

  Future<void> _onTokenRefreshed(
    FcmTokenRefreshed event,
    Emitter<NotificationState> emit,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _saveFcmToken(uid, event.token);
  }

  void _onTapped(
    NotificationTapped event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationTapHandled(event.payload ?? '/dashboard'));
  }

  Future<void> _onSchedule(
    ScheduleDailyReminder event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _scheduleDailyReminder(
      hour: event.hour,
      minute: event.minute,
    );
    await result.fold(
      (failure) async => emit(NotificationError(failure.message)),
      (_) async {
        await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
          AppSettingsCompanion(
            reminderEnabled: const Value(true),
            reminderHour: Value(event.hour),
            reminderMinute: Value(event.minute),
          ),
        );
        emit(NotificationScheduled(hour: event.hour, minute: event.minute));
      },
    );
  }

  Future<void> _onCancel(
    CancelDailyReminder event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _cancelDailyReminder();
    await result.fold(
      (failure) async {
        FirebaseCrashlytics.instance.recordError(failure, null);
        emit(NotificationError(failure.message));
      },
      (_) async {
        await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
          const AppSettingsCompanion(reminderEnabled: Value(false)),
        );
        emit(const NotificationCancelled());
      },
    );
  }

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    return super.close();
  }
}
