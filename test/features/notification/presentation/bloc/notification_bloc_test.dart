import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/notification/notification_launch_holder.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/notification/domain/usecases/cancel_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/register_fcm_token_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/request_permission_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/schedule_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/set_push_preference_usecase.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';

class MockRequestPermissionUseCase extends Mock
    implements RequestPermissionUseCase {}

class MockRegisterFcmTokenUseCase extends Mock
    implements RegisterFcmTokenUseCase {}

class MockSetPushPreferenceUseCase extends Mock
    implements SetPushPreferenceUseCase {}

class MockScheduleDailyReminderUseCase extends Mock
    implements ScheduleDailyReminderUseCase {}

class MockCancelDailyReminderUseCase extends Mock
    implements CancelDailyReminderUseCase {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockNotificationLocalDatasource extends Mock
    implements NotificationLocalDatasource {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

void main() {
  late MockRequestPermissionUseCase mockRequestPermission;
  late MockRegisterFcmTokenUseCase mockRegisterToken;
  late MockSetPushPreferenceUseCase mockSetPushPreference;
  late MockScheduleDailyReminderUseCase mockScheduleDailyReminder;
  late MockCancelDailyReminderUseCase mockCancelDailyReminder;
  late MockFirebaseMessaging mockMessaging;
  late MockFirebaseAuth mockAuth;
  late MockNotificationLocalDatasource mockLocal;
  late NotificationLaunchHolder launchHolder;
  late AppDatabase testDb;

  const tUid = 'uid-1';

  setUp(() {
    mockRequestPermission = MockRequestPermissionUseCase();
    mockRegisterToken = MockRegisterFcmTokenUseCase();
    mockSetPushPreference = MockSetPushPreferenceUseCase();
    mockScheduleDailyReminder = MockScheduleDailyReminderUseCase();
    mockCancelDailyReminder = MockCancelDailyReminderUseCase();
    mockMessaging = MockFirebaseMessaging();
    mockAuth = MockFirebaseAuth();
    mockLocal = MockNotificationLocalDatasource();
    launchHolder = NotificationLaunchHolder();
    testDb = AppDatabase(NativeDatabase.memory());

    when(() => mockAuth.currentUser).thenReturn(null);
    when(
      () => mockRegisterToken(any()),
    ).thenAnswer((_) async => const Right(null));
  });

  tearDown(() async => testDb.close());

  NotificationBloc buildBloc() => NotificationBloc(
    requestPermission: mockRequestPermission,
    registerToken: mockRegisterToken,
    setPushPreference: mockSetPushPreference,
    scheduleDailyReminder: mockScheduleDailyReminder,
    cancelDailyReminder: mockCancelDailyReminder,
    messaging: mockMessaging,
    auth: mockAuth,
    local: mockLocal,
    launchHolder: launchHolder,
    db: testDb,
  );

  group('RequestPermission', () {
    blocTest<NotificationBloc, NotificationState>(
      'granted → NotificationPermissionGranted',
      build: buildBloc,
      setUp: () => when(
        () => mockRequestPermission(),
      ).thenAnswer((_) async => const Right(true)),
      act: (bloc) => bloc.add(const RequestPermission()),
      expect: () => [const NotificationPermissionGranted()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'granted + uid ada → registerToken(uid) dipanggil',
      build: buildBloc,
      setUp: () {
        final user = MockUser();
        when(() => user.uid).thenReturn(tUid);
        when(() => mockAuth.currentUser).thenReturn(user);
        when(
          () => mockRequestPermission(),
        ).thenAnswer((_) async => const Right(true));
      },
      act: (bloc) => bloc.add(const RequestPermission()),
      wait: const Duration(milliseconds: 400), // lewati delay iOS 300ms
      verify: (_) => verify(() => mockRegisterToken(tUid)).called(1),
    );

    blocTest<NotificationBloc, NotificationState>(
      'denied → NotificationPermissionDenied',
      build: buildBloc,
      setUp: () => when(
        () => mockRequestPermission(),
      ).thenAnswer((_) async => const Right(false)),
      act: (bloc) => bloc.add(const RequestPermission()),
      expect: () => [const NotificationPermissionDenied()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'failure → NotificationError',
      build: buildBloc,
      setUp: () => when(() => mockRequestPermission()).thenAnswer(
        (_) async => const Left(ServerFailure('Gagal meminta izin.')),
      ),
      act: (bloc) => bloc.add(const RequestPermission()),
      expect: () => [const NotificationError('Gagal meminta izin.')],
    );
  });

  group('FcmTokenRefreshed', () {
    blocTest<NotificationBloc, NotificationState>(
      'uid ada → registerToken(uid) dipanggil',
      build: buildBloc,
      setUp: () {
        final user = MockUser();
        when(() => user.uid).thenReturn(tUid);
        when(() => mockAuth.currentUser).thenReturn(user);
      },
      act: (bloc) => bloc.add(const FcmTokenRefreshed('tok-baru')),
      verify: (_) => verify(() => mockRegisterToken(tUid)).called(1),
    );
  });

  group('SetPushPreference', () {
    blocTest<NotificationBloc, NotificationState>(
      'uid ada → setPushPreference(uid, false) dipanggil',
      build: buildBloc,
      setUp: () {
        final user = MockUser();
        when(() => user.uid).thenReturn(tUid);
        when(() => mockAuth.currentUser).thenReturn(user);
        when(
          () => mockSetPushPreference(tUid, false),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const SetPushPreference(false)),
      verify: (_) => verify(() => mockSetPushPreference(tUid, false)).called(1),
    );

    blocTest<NotificationBloc, NotificationState>(
      'gagal → NotificationError',
      build: buildBloc,
      setUp: () {
        final user = MockUser();
        when(() => user.uid).thenReturn(tUid);
        when(() => mockAuth.currentUser).thenReturn(user);
        when(() => mockSetPushPreference(tUid, true)).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal menyimpan.')),
        );
      },
      act: (bloc) => bloc.add(const SetPushPreference(true)),
      expect: () => [const NotificationError('Gagal menyimpan.')],
    );
  });

  group('CheckInitialMessage', () {
    blocTest<NotificationBloc, NotificationState>(
      'getInitialMessage ada route → tulis holder, TIDAK emit NotificationTapHandled',
      build: buildBloc,
      setUp: () {
        final msg = MockRemoteMessage();
        when(() => msg.data).thenReturn({'route': '/budget'});
        when(
          () => mockMessaging.getInitialMessage(),
        ).thenAnswer((_) async => msg);
      },
      act: (bloc) => bloc.add(const CheckInitialMessage()),
      expect: () => [], // tidak ada state — hanya side-effect ke holder
      verify: (_) => expect(launchHolder.takePendingRoute(), '/budget'),
    );

    blocTest<NotificationBloc, NotificationState>(
      'getInitialMessage null → holder tetap kosong',
      build: buildBloc,
      setUp: () => when(
        () => mockMessaging.getInitialMessage(),
      ).thenAnswer((_) async => null),
      act: (bloc) => bloc.add(const CheckInitialMessage()),
      expect: () => [],
      verify: (_) => expect(launchHolder.takePendingRoute(), isNull),
    );
  });

  group('NotificationTapped', () {
    blocTest<NotificationBloc, NotificationState>(
      'payload non-null → NotificationTapHandled(route)',
      build: buildBloc,
      act: (bloc) => bloc.add(const NotificationTapped('/transactions')),
      expect: () => [const NotificationTapHandled('/transactions')],
    );
    blocTest<NotificationBloc, NotificationState>(
      'payload null → fallback /dashboard',
      build: buildBloc,
      act: (bloc) => bloc.add(const NotificationTapped(null)),
      expect: () => [const NotificationTapHandled('/dashboard')],
    );
  });

  group('ScheduleDailyReminder', () {
    blocTest<NotificationBloc, NotificationState>(
      'sukses → NotificationScheduled',
      build: buildBloc,
      setUp: () => when(
        () => mockScheduleDailyReminder(hour: 20, minute: 0),
      ).thenAnswer((_) async => const Right<Failure, void>(null)),
      act: (bloc) => bloc.add(const ScheduleDailyReminder(hour: 20, minute: 0)),
      expect: () => [const NotificationScheduled(hour: 20, minute: 0)],
    );
  });
}
