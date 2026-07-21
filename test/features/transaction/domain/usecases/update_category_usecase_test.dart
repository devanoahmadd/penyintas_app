import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/category_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_category_usecase.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FakeCategoryEntity extends Fake implements CategoryEntity {}

void main() {
  late MockCategoryRepository repo;
  late UpdateCategoryUseCase usecase;

  setUpAll(() {
    registerFallbackValue(FakeCategoryEntity());
  });

  setUp(() {
    repo = MockCategoryRepository();
    usecase = UpdateCategoryUseCase(repo);
  });

  final tCustom = CategoryEntity(
    id: 1,
    slug: 'gym',
    labelOverride: 'Gym & Olahraga',
    isBuiltIn: false,
    isLimitable: true,
    type: 'expense',
    sortOrder: 100,
    iconSlug: 'fitness',
  );

  test('berhasil update custom category', () async {
    when(
      () => repo.updateCategory(tCustom),
    ).thenAnswer((_) async => const Right(null));
    final result = await usecase(tCustom);
    expect(result.isRight(), true);
    verify(() => repo.updateCategory(tCustom)).called(1);
  });

  test('gagal update built-in category — return ValidationFailure', () async {
    final builtIn = tCustom.copyWith(isBuiltIn: true);
    final result = await usecase(builtIn);
    expect(result.isLeft(), true);
    result.fold(
      (f) => expect(f, isA<ValidationFailure>()),
      (_) => fail('should fail'),
    );
    verifyNever(() => repo.updateCategory(any()));
  });

  test(
    'gagal update category dengan labelOverride kosong — return ValidationFailure',
    () async {
      final emptyLabel = tCustom.copyWith(labelOverride: '   ');
      final result = await usecase(emptyLabel);
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('should fail'),
      );
      verifyNever(() => repo.updateCategory(any()));
    },
  );
}
