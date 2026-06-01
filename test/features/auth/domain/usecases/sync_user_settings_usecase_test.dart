import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/repositories/user_settings_repository.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sync_user_settings_usecase.dart';

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

void main() {
  late SyncUserSettingsUseCase useCase;
  late MockUserSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockUserSettingsRepository();
    useCase = SyncUserSettingsUseCase(mockRepo);
  });

  test('should call repository.syncFromRemote and return Right(unit)', () async {
    when(() => mockRepo.syncFromRemote())
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(const NoParams());

    expect(result, const Right(unit));
    verify(() => mockRepo.syncFromRemote()).called(1);
    verifyNoMoreInteractions(mockRepo);
  });
}
