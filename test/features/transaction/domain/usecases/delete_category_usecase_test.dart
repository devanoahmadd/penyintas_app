import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/category_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_category_usecase.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repo;
  late DeleteCategoryUseCase usecase;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    repo = MockCategoryRepository();
    usecase = DeleteCategoryUseCase(repo);
  });

  test('berhasil delete custom category', () async {
    when(
      () => repo.deleteCategory('gym'),
    ).thenAnswer((_) async => const Right(null));
    final result = await usecase(
      const DeleteCategoryParams(slug: 'gym', isBuiltIn: false),
    );
    expect(result.isRight(), true);
    verify(() => repo.deleteCategory('gym')).called(1);
  });

  test('gagal delete built-in category — return ValidationFailure', () async {
    final result = await usecase(
      const DeleteCategoryParams(slug: 'food', isBuiltIn: true),
    );
    expect(result.isLeft(), true);
    result.fold(
      (f) => expect(f, isA<ValidationFailure>()),
      (_) => fail('should fail'),
    );
    verifyNever(() => repo.deleteCategory(any()));
  });
}
