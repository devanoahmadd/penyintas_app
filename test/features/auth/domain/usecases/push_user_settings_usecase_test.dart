import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/repositories/user_settings_repository.dart';
import 'package:penyintas_app/features/auth/domain/usecases/push_user_settings_usecase.dart';

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

void main() {
  late PushUserSettingsUseCase useCase;
  late MockUserSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockUserSettingsRepository();
    useCase = PushUserSettingsUseCase(mockRepo);
  });

  test('should call repository.pushToRemote and return Right(unit)', () async {
    when(() => mockRepo.pushToRemote())
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(const NoParams());

    expect(result, const Right(unit));
    verify(() => mockRepo.pushToRemote()).called(1);
    verifyNoMoreInteractions(mockRepo);
  });
}
