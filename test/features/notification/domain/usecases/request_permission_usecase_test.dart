import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:penyintas_app/features/notification/domain/usecases/request_permission_usecase.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockNotificationRepository mockRepo;
  late RequestPermissionUseCase useCase;

  setUp(() {
    mockRepo = MockNotificationRepository();
    useCase = RequestPermissionUseCase(mockRepo);
  });

  group('RequestPermissionUseCase', () {
    test('returns Right(true) when repository grants permission', () async {
      when(
        () => mockRepo.requestPermission(),
      ).thenAnswer((_) async => const Right(true));

      final result = await useCase();

      expect(result, const Right<Failure, bool>(true));
      verify(() => mockRepo.requestPermission()).called(1);
    });

    test('returns Left(Failure) when repository returns a failure', () async {
      when(() => mockRepo.requestPermission()).thenAnswer(
        (_) async =>
            const Left(ServerFailure('Gagal meminta izin notifikasi.')),
      );

      final result = await useCase();

      expect(
        result,
        const Left<Failure, bool>(
          ServerFailure('Gagal meminta izin notifikasi.'),
        ),
      );
    });
  });
}
