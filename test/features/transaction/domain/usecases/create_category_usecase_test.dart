import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/category_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/create_category_usecase.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FakeCategoryEntity extends Fake implements CategoryEntity {}

void main() {
  late MockCategoryRepository repo;
  late CreateCategoryUseCase usecase;

  setUpAll(() {
    registerFallbackValue(FakeCategoryEntity());
  });

  setUp(() {
    repo = MockCategoryRepository();
    usecase = CreateCategoryUseCase(repo);
  });

  final tCustom = CategoryEntity(
    id: 0,
    slug: 'gym',
    labelOverride: 'Gym & Olahraga',
    isBuiltIn: false,
    isLimitable: true,
    type: 'expense',
    sortOrder: 100,
    iconSlug: 'fitness',
  );

  test('berhasil create custom category', () async {
    when(
      () => repo.createCategory(tCustom),
    ).thenAnswer((_) async => Right(tCustom.copyWith(id: 1)));
    final result = await usecase(tCustom);
    expect(result.isRight(), true);
    verify(() => repo.createCategory(tCustom)).called(1);
  });

  test('gagal create built-in category — return ValidationFailure', () async {
    final builtIn = tCustom.copyWith(isBuiltIn: true);
    final result = await usecase(builtIn);
    expect(result.isLeft(), true);
    result.fold(
      (f) => expect(f, isA<ValidationFailure>()),
      (_) => fail('should fail'),
    );
    verifyNever(() => repo.createCategory(any()));
  });

  test('repository error → Left(failure)', () async {
    when(
      () => repo.createCategory(tCustom),
    ).thenAnswer((_) async => const Left(CacheFailure('DB error')));
    final result = await usecase(tCustom);
    expect(result.isLeft(), true);
  });
}
