import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/notification/notification_launch_holder.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/notification/data/services/daily_reminder_scheduler.dart';
import 'package:penyintas_app/features/notification/domain/usecases/register_fcm_token_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/request_permission_usecase.dart';
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

class MockDailyReminderScheduler extends Mock
    implements DailyReminderScheduler {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockNotificationLocalDatasource extends Mock
    implements NotificationLocalDatasource {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

void main() {
  // `initialize(onTap:)` bertipe fungsi non-nullable — `any(named:)` menuntut
  // nilai cadangan terdaftar untuk tipe itu.
  setUpAll(() => registerFallbackValue((String? _) {}));

  late MockRequestPermissionUseCase mockRequestPermission;
  late MockRegisterFcmTokenUseCase mockRegisterToken;
  late MockSetPushPreferenceUseCase mockSetPushPreference;
  late MockDailyReminderScheduler mockScheduler;
  late MockFirebaseMessaging mockMessaging;
  late MockFirebaseAuth mockAuth;
  late MockNotificationLocalDatasource mockLocal;
  late NotificationLaunchHolder launchHolder;
  late AppDatabase testDb;

  const tUid = 'uid-1';

  /// Jam yang dibaca scheduler dari `app_settings` saat `reschedule()`
  /// dipanggil — inti T34.
  int? jamYangTerbaca;

  setUp(() {
    mockRequestPermission = MockRequestPermissionUseCase();
    mockRegisterToken = MockRegisterFcmTokenUseCase();
    mockSetPushPreference = MockSetPushPreferenceUseCase();
    mockScheduler = MockDailyReminderScheduler();
    mockMessaging = MockFirebaseMessaging();
    mockAuth = MockFirebaseAuth();
    mockLocal = MockNotificationLocalDatasource();
    launchHolder = NotificationLaunchHolder();
    testDb = AppDatabase(NativeDatabase.memory());
    jamYangTerbaca = null;

    when(() => mockAuth.currentUser).thenReturn(null);
    when(
      () => mockRegisterToken(any()),
    ).thenAnswer((_) async => const Right(null));
    when(() => mockScheduler.reschedule()).thenAnswer((_) async {});
  });

  tearDown(() async => testDb.close());

  NotificationBloc buildBloc() => NotificationBloc(
    requestPermission: mockRequestPermission,
    registerToken: mockRegisterToken,
    setPushPreference: mockSetPushPreference,
    scheduler: mockScheduler,
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

  group('InitNotification — satu pintu penjadwalan', () {
    void siapkanInit() {
      when(
        () => mockLocal.initialize(onTap: any(named: 'onTap')),
      ).thenAnswer((_) async {});
      when(
        () => mockMessaging.onTokenRefresh,
      ).thenAnswer((_) => const Stream<String>.empty());
      when(
        () => mockMessaging.getInitialMessage(),
      ).thenAnswer((_) async => null);
    }

    // ASSERT YANG BERPINDAH. Sebelum Task 15, `_onInit` membaca `app_settings`
    // sendiri lalu memanggil `_local.scheduleDailyReminder(...)` polos —
    // penjadwalan yang tidak tahu apa-apa soal streak, dan karena itu tetap
    // membunyikan pengingat pukul 20 di hari yang sudah aman. Sekarang SATU
    // PINTU: `_scheduler.reschedule()`.
    blocTest<NotificationBloc, NotificationState>(
      'T-INIT — InitNotification memanggil scheduler.reschedule(), '
      'BUKAN datasource langsung',
      build: buildBloc,
      setUp: () async {
        siapkanInit();
        await testDb
            .into(testDb.appSettings)
            .insertOnConflictUpdate(
              const AppSettingsCompanion(
                id: Value(1),
                reminderEnabled: Value(true),
                reminderHour: Value(20),
                reminderMinute: Value(0),
              ),
            );
      },
      act: (bloc) => bloc.add(const InitNotification()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => mockScheduler.reschedule()).called(1);
        verifyNever(
          () => mockLocal.scheduleDailyReminder(
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
            skipToday: any(named: 'skipToday'),
          ),
        );
      },
    );

    // Pintu tunggal itu juga berlaku saat barisnya TIDAK ada (sesudah logout):
    // bloc tidak lagi memutuskan sendiri, ia menyerahkannya ke scheduler.
    blocTest<NotificationBloc, NotificationState>(
      'baris app_settings tidak ada → tetap memanggil reschedule()',
      build: buildBloc,
      setUp: siapkanInit,
      act: (bloc) => bloc.add(const InitNotification()),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verify(() => mockScheduler.reschedule()).called(1),
    );
  });

  group('ScheduleDailyReminder', () {
    Future<AppSetting?> bacaSettings() => (testDb.select(
      testDb.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    Future<void> pasangSettings({
      required bool enabled,
      required int hour,
      required int minute,
    }) => testDb
        .into(testDb.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            id: const Value(1),
            reminderEnabled: Value(enabled),
            reminderHour: Value(hour),
            reminderMinute: Value(minute),
          ),
        );

    blocTest<NotificationBloc, NotificationState>(
      'sukses → NotificationScheduled + reschedule() dipanggil',
      build: buildBloc,
      act: (bloc) => bloc.add(const ScheduleDailyReminder(hour: 20, minute: 0)),
      expect: () => [const NotificationScheduled(hour: 20, minute: 0)],
      verify: (_) => verify(() => mockScheduler.reschedule()).called(1),
    );

    // T34 — urutan tulis-dulu.
    blocTest<NotificationBloc, NotificationState>(
      'T34 — ScheduleDailyReminder MENYIMPAN app_settings sebelum reschedule, '
      'sehingga penjadwalan memakai jam BARU',
      build: buildBloc,
      setUp: () async {
        await pasangSettings(enabled: true, hour: 20, minute: 0);
        when(() => mockScheduler.reschedule()).thenAnswer((_) async {
          jamYangTerbaca = (await bacaSettings())?.reminderHour;
        });
      },
      act: (bloc) => bloc.add(const ScheduleDailyReminder(hour: 21, minute: 0)),
      verify: (_) => expect(
        jamYangTerbaca,
        21,
        reason: 'urutan lama (jadwalkan dulu, simpan belakangan) memberi 20',
      ),
    );

    // D-12 — `settings_page.dart` mengembalikan posisi toggle saat menerima
    // `NotificationError` dan mengandalkan urutan LAMA yang gagal SEBELUM apa
    // pun tersimpan. Karena urutannya kini dibalik, kegagalan harus menulis
    // balik nilai lama — kalau tidak, toggle mati di layar sementara
    // `app_settings` bilang hidup, dan cold start berikutnya menghidupkannya
    // lagi.
    blocTest<NotificationBloc, NotificationState>(
      'D-12 — reschedule melempar → app_settings dipulihkan ke nilai lama',
      build: buildBloc,
      setUp: () async {
        await pasangSettings(enabled: false, hour: 20, minute: 0);
        when(() => mockScheduler.reschedule()).thenThrow(Exception('gagal'));
      },
      act: (bloc) =>
          bloc.add(const ScheduleDailyReminder(hour: 21, minute: 30)),
      expect: () => [isA<NotificationError>()],
      verify: (_) async {
        final s = await bacaSettings();
        expect(s?.reminderEnabled, isFalse);
        expect(s?.reminderHour, 20);
        expect(s?.reminderMinute, 0);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'D-12 — baris belum ada dan reschedule melempar → baris tidak tertinggal',
      build: buildBloc,
      setUp: () =>
          when(() => mockScheduler.reschedule()).thenThrow(Exception('gagal')),
      act: (bloc) =>
          bloc.add(const ScheduleDailyReminder(hour: 21, minute: 30)),
      expect: () => [isA<NotificationError>()],
      verify: (_) async => expect(await bacaSettings(), isNull),
    );
  });

  group('CancelDailyReminder', () {
    blocTest<NotificationBloc, NotificationState>(
      'menyimpan reminderEnabled=false lalu lewat pintu yang sama',
      build: buildBloc,
      setUp: () => testDb
          .into(testDb.appSettings)
          .insertOnConflictUpdate(
            const AppSettingsCompanion(
              id: Value(1),
              reminderEnabled: Value(true),
            ),
          ),
      act: (bloc) => bloc.add(const CancelDailyReminder()),
      expect: () => [const NotificationCancelled()],
      verify: (_) async {
        verify(() => mockScheduler.reschedule()).called(1);
        verifyNever(() => mockLocal.cancelDailyReminder());
        final s = await (testDb.select(
          testDb.appSettings,
        )..where((t) => t.id.equals(1))).getSingleOrNull();
        expect(s?.reminderEnabled, isFalse);
      },
    );
  });
}
