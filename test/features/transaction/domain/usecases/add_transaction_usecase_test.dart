import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class FakeTransactionEntity extends Fake implements TransactionEntity {}

void main() {
  late AddTransactionUseCase useCase;
  late MockTransactionRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeTransactionEntity());
  });

  setUp(() {
    mockRepo = MockTransactionRepository();
    useCase = AddTransactionUseCase(mockRepo);
  });

  final tEntity = TransactionEntity(
    id: 'test-id',
    amount: 50000,
    category: TransactionCategory.food,
    type: TransactionType.expense,
    date: DateTime(2026, 5, 8),
    isFixed: false,
    isSynced: false,
    createdAt: DateTime(2026, 5, 8),
    updatedAt: DateTime(2026, 5, 8),
  );

  test('should call repository.addTransaction and return Right(null)', () async {
    when(() => mockRepo.addTransaction(any()))
        .thenAnswer((_) async => const Right(null));

    final result = await useCase(tEntity);

    expect(result, const Right<dynamic, void>(null));
    verify(() => mockRepo.addTransaction(tEntity)).called(1);
    verifyNoMoreInteractions(mockRepo);
  });
}
