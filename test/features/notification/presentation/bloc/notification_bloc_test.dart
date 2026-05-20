import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/notification/domain/usecases/cancel_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/request_permission_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/save_fcm_token_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/schedule_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';

class MockRequestPermissionUseCase extends Mock implements RequestPermissionUseCase {}

class MockSaveFcmTokenUseCase extends Mock implements SaveFcmTokenUseCase {}

class MockScheduleDailyReminderUseCase extends Mock implements ScheduleDailyReminderUseCase {}

class MockCancelDailyReminderUseCase extends Mock implements CancelDailyReminderUseCase {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockNotificationLocalDatasource extends Mock implements NotificationLocalDatasource {}

void main() {
  late MockRequestPermissionUseCase mockRequestPermission;
  late MockSaveFcmTokenUseCase mockSaveFcmToken;
  late MockScheduleDailyReminderUseCase mockScheduleDailyReminder;
  late MockCancelDailyReminderUseCase mockCancelDailyReminder;
  late MockFirebaseMessaging mockMessaging;
  late MockFirebaseAuth mockAuth;
  late MockNotificationLocalDatasource mockLocal;
  late AppDatabase testDb;

  setUp(() {
    mockRequestPermission = MockRequestPermissionUseCase();
    mockSaveFcmToken = MockSaveFcmTokenUseCase();
    mockScheduleDailyReminder = MockScheduleDailyReminderUseCase();
    mockCancelDailyReminder = MockCancelDailyReminderUseCase();
    mockMessaging = MockFirebaseMessaging();
    mockAuth = MockFirebaseAuth();
    mockLocal = MockNotificationLocalDatasource();
    testDb = AppDatabase(NativeDatabase.memory());

    // No current user → skip the FCM token-save branch in _onRequestPermission
    when(() => mockAuth.currentUser).thenReturn(null);
  });

  tearDown(() async => testDb.close());

  NotificationBloc buildBloc() => NotificationBloc(
        requestPermission: mockRequestPermission,
        saveFcmToken: mockSaveFcmToken,
        scheduleDailyReminder: mockScheduleDailyReminder,
        cancelDailyReminder: mockCancelDailyReminder,
        messaging: mockMessaging,
        auth: mockAuth,
        local: mockLocal,
        db: testDb,
      );

  group('RequestPermission', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationPermissionGranted when permission is granted',
      build: buildBloc,
      setUp: () {
        when(() => mockRequestPermission())
            .thenAnswer((_) async => const Right(true));
      },
      act: (bloc) => bloc.add(const RequestPermission()),
      expect: () => [const NotificationPermissionGranted()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationPermissionDenied when permission is denied',
      build: buildBloc,
      setUp: () {
        when(() => mockRequestPermission())
            .thenAnswer((_) async => const Right(false));
      },
      act: (bloc) => bloc.add(const RequestPermission()),
      expect: () => [const NotificationPermissionDenied()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationError when use case returns failure',
      build: buildBloc,
      setUp: () {
        when(() => mockRequestPermission()).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal meminta izin.')),
        );
      },
      act: (bloc) => bloc.add(const RequestPermission()),
      expect: () => [const NotificationError('Gagal meminta izin.')],
    );
  });

  group('NotificationTapped', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationTapHandled with given route when payload is not null',
      build: buildBloc,
      act: (bloc) => bloc.add(const NotificationTapped('/transactions')),
      expect: () => [const NotificationTapHandled('/transactions')],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationTapHandled with /dashboard fallback when payload is null',
      build: buildBloc,
      act: (bloc) => bloc.add(const NotificationTapped(null)),
      expect: () => [const NotificationTapHandled('/dashboard')],
    );
  });

  group('ScheduleDailyReminder', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationScheduled when scheduling succeeds',
      build: buildBloc,
      setUp: () {
        when(() => mockScheduleDailyReminder(hour: 20, minute: 0))
            .thenAnswer((_) async => const Right<Failure, void>(null));
      },
      act: (bloc) => bloc.add(const ScheduleDailyReminder(hour: 20, minute: 0)),
      expect: () => [const NotificationScheduled(hour: 20, minute: 0)],
    );
  });
}
