import 'dart:async';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/notification/notification_launch_holder.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/notification/domain/usecases/cancel_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/register_fcm_token_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/request_permission_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/schedule_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/set_push_preference_usecase.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required RequestPermissionUseCase requestPermission,
    required RegisterFcmTokenUseCase registerToken,
    required SetPushPreferenceUseCase setPushPreference,
    required ScheduleDailyReminderUseCase scheduleDailyReminder,
    required CancelDailyReminderUseCase cancelDailyReminder,
    required FirebaseMessaging messaging,
    required FirebaseAuth auth,
    required NotificationLocalDatasource local,
    required NotificationLaunchHolder launchHolder,
    required AppDatabase db,
  })  : _requestPermission = requestPermission,
        _registerToken = registerToken,
        _setPushPreference = setPushPreference,
        _scheduleDailyReminder = scheduleDailyReminder,
        _cancelDailyReminder = cancelDailyReminder,
        _messaging = messaging,
        _auth = auth,
        _local = local,
        _launchHolder = launchHolder,
        _db = db,
        super(const NotificationInitial()) {
    on<InitNotification>(_onInit);
    on<RequestPermission>(_onRequestPermission);
    on<FcmTokenRefreshed>(_onTokenRefreshed);
    on<NotificationTapped>(_onTapped);
    on<ScheduleDailyReminder>(_onSchedule);
    on<CancelDailyReminder>(_onCancel);
    on<SetPushPreference>(_onSetPushPreference);
    on<CheckInitialMessage>(_onCheckInitialMessage);
  }

  final RequestPermissionUseCase _requestPermission;
  final RegisterFcmTokenUseCase _registerToken;
  final SetPushPreferenceUseCase _setPushPreference;
  final ScheduleDailyReminderUseCase _scheduleDailyReminder;
  final CancelDailyReminderUseCase _cancelDailyReminder;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final NotificationLocalDatasource _local;
  final NotificationLaunchHolder _launchHolder;
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
        // Foreground: FCM tak meng-auto-display di state ini. Tampilkan sendiri
        // sebagai local notif. Navigasi HANYA saat user mengetuk (via onTap di
        // initialize, atau onMessageOpenedApp) — bukan saat pesan datang.
        final notif = message.notification;
        if (notif == null) return; // pesan data-only: tak ada yang ditampilkan
        unawaited(_local.show(
          title: notif.title ?? '',
          body: notif.body ?? '',
          payload: message.data['route'] as String?,
        ));
      });

      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final route = message.data['route'] as String?;
        if (route != null) add(NotificationTapped(route));
      });

      // G6: app diluncurkan dari terminated via tap notif → simpan route.
      add(const CheckInitialMessage());

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
              // iOS: beri jeda agar dialog izin native sempat tertutup sebelum
              // getToken (di dalam registerToken) memicu dialog kedua.
              await Future.delayed(const Duration(milliseconds: 300));
              await _registerToken(uid);
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
    await _registerToken(uid);
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

  Future<void> _onSetPushPreference(
    SetPushPreference event,
    Emitter<NotificationState> emit,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final result = await _setPushPreference(uid, event.enabled);
    result.fold(
      (failure) => emit(NotificationError(failure.message)),
      (_) {}, // sukses: nilai sudah optimistik di widget
    );
  }

  Future<void> _onCheckInitialMessage(
    CheckInitialMessage event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final initial = await _messaging.getInitialMessage();
      final route = initial?.data['route'] as String?;
      // K3: simpan ke holder — SplashPage menerapkannya pasca-bootstrap.
      if (route != null) _launchHolder.pendingRoute = route;
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
    }
  }

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    return super.close();
  }
}
