import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/create_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_categories_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_category_usecase.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/category_bloc.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockCreateCategoryUseCase extends Mock implements CreateCategoryUseCase {}

class MockUpdateCategoryUseCase extends Mock implements UpdateCategoryUseCase {}

class MockDeleteCategoryUseCase extends Mock implements DeleteCategoryUseCase {}

CategoryEntity _makeBuiltIn({String slug = 'food', int sortOrder = 10}) =>
    CategoryEntity(
      id: 1,
      slug: slug,
      labelKey: 'category_$slug',
      isBuiltIn: true,
      isLimitable: true,
      type: 'expense',
      sortOrder: sortOrder,
    );

CategoryEntity _makeCustom({
  int id = 99,
  String slug = 'custom_a',
  String label = 'Kustom A',
  int sortOrder = 100,
}) => CategoryEntity(
  id: id,
  slug: slug,
  labelOverride: label,
  isBuiltIn: false,
  isLimitable: true,
  type: 'expense',
  sortOrder: sortOrder,
);

CategoryBloc _makeBloc({
  required MockGetCategoriesUseCase getCategories,
  required MockCreateCategoryUseCase createCategory,
  required MockUpdateCategoryUseCase updateCategory,
  required MockDeleteCategoryUseCase deleteCategory,
}) => CategoryBloc(
  getCategories: getCategories,
  createCategory: createCategory,
  updateCategory: updateCategory,
  deleteCategory: deleteCategory,
);

void main() {
  late MockGetCategoriesUseCase mockGet;
  late MockCreateCategoryUseCase mockCreate;
  late MockUpdateCategoryUseCase mockUpdate;
  late MockDeleteCategoryUseCase mockDelete;

  setUp(() {
    mockGet = MockGetCategoriesUseCase();
    mockCreate = MockCreateCategoryUseCase();
    mockUpdate = MockUpdateCategoryUseCase();
    mockDelete = MockDeleteCategoryUseCase();

    registerFallbackValue(const NoParams());
    registerFallbackValue(_makeCustom());
    registerFallbackValue(
      const DeleteCategoryParams(slug: 'x', isBuiltIn: false),
    );
  });

  group('LoadCategories', () {
    final cats = [_makeBuiltIn(), _makeCustom()];

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryLoading, CategoryLoaded] on success',
      build: () {
        when(() => mockGet(any())).thenAnswer((_) async => Right(cats));
        return _makeBloc(
          getCategories: mockGet,
          createCategory: mockCreate,
          updateCategory: mockUpdate,
          deleteCategory: mockDelete,
        );
      },
      act: (bloc) => bloc.add(const LoadCategories()),
      expect: () => [const CategoryLoading(), CategoryLoaded(categories: cats)],
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryLoading, CategoryError] on failure',
      build: () {
        when(
          () => mockGet(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('DB error')));
        return _makeBloc(
          getCategories: mockGet,
          createCategory: mockCreate,
          updateCategory: mockUpdate,
          deleteCategory: mockDelete,
        );
      },
      act: (bloc) => bloc.add(const LoadCategories()),
      expect: () => [const CategoryLoading(), const CategoryError('DB error')],
    );
  });

  group('CreateCategory', () {
    final existing = _makeBuiltIn(sortOrder: 10);
    final input = _makeCustom(id: 0, slug: 'custom_a', sortOrder: 100);
    final created = _makeCustom(id: 99, slug: 'custom_a', sortOrder: 100);
    final updatedList = [existing, created];

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryActionLoading, CategoryLoaded(created)] on success',
      setUp: () {
        when(() => mockCreate(any())).thenAnswer((_) async => Right(created));
        when(() => mockGet(any())).thenAnswer((_) async => Right(updatedList));
      },
      build: () => _makeBloc(
        getCategories: mockGet,
        createCategory: mockCreate,
        updateCategory: mockUpdate,
        deleteCategory: mockDelete,
      ),
      seed: () => CategoryLoaded(categories: [existing]),
      act: (bloc) => bloc.add(CreateCategory(input)),
      expect: () => [
        CategoryActionLoading(categories: [existing]),
        CategoryLoaded(
          categories: updatedList,
          successType: CategorySuccessType.created,
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryActionLoading, CategoryError] on duplicate slug',
      setUp: () {
        when(() => mockCreate(any())).thenAnswer(
          (_) async => const Left(
            CacheFailure('Kategori dengan nama serupa sudah ada.'),
          ),
        );
      },
      build: () => _makeBloc(
        getCategories: mockGet,
        createCategory: mockCreate,
        updateCategory: mockUpdate,
        deleteCategory: mockDelete,
      ),
      seed: () => CategoryLoaded(categories: [existing]),
      act: (bloc) => bloc.add(CreateCategory(input)),
      expect: () => [
        CategoryActionLoading(categories: [existing]),
        const CategoryError('Kategori dengan nama serupa sudah ada.'),
      ],
    );
  });

  group('UpdateCategory', () {
    final existing = _makeBuiltIn(sortOrder: 10);
    final oldCustom = _makeCustom(id: 99, label: 'Lama');
    final newCustom = _makeCustom(id: 99, label: 'Baru');

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryActionLoading, CategoryLoaded(updated)] on success',
      setUp: () {
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        when(
          () => mockGet(any()),
        ).thenAnswer((_) async => Right([existing, newCustom]));
      },
      build: () => _makeBloc(
        getCategories: mockGet,
        createCategory: mockCreate,
        updateCategory: mockUpdate,
        deleteCategory: mockDelete,
      ),
      seed: () => CategoryLoaded(categories: [existing, oldCustom]),
      act: (bloc) => bloc.add(UpdateCategory(newCustom)),
      expect: () => [
        CategoryActionLoading(categories: [existing, oldCustom]),
        CategoryLoaded(
          categories: [existing, newCustom],
          successType: CategorySuccessType.updated,
        ),
      ],
    );
  });

  group('DeleteCategory', () {
    final builtIn = _makeBuiltIn(sortOrder: 10);
    final custom = _makeCustom(id: 99, slug: 'custom_a');

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryActionLoading, CategoryLoaded(deleted)] on success',
      setUp: () {
        when(
          () => mockDelete(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        when(() => mockGet(any())).thenAnswer((_) async => Right([builtIn]));
      },
      build: () => _makeBloc(
        getCategories: mockGet,
        createCategory: mockCreate,
        updateCategory: mockUpdate,
        deleteCategory: mockDelete,
      ),
      seed: () => CategoryLoaded(categories: [builtIn, custom]),
      act: (bloc) => bloc.add(const DeleteCategory('custom_a')),
      expect: () => [
        CategoryActionLoading(categories: [builtIn, custom]),
        CategoryLoaded(
          categories: [builtIn],
          successType: CategorySuccessType.deleted,
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [CategoryActionLoading, CategoryError] on delete failure',
      setUp: () {
        when(
          () => mockDelete(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Gagal menghapus.')));
      },
      build: () => _makeBloc(
        getCategories: mockGet,
        createCategory: mockCreate,
        updateCategory: mockUpdate,
        deleteCategory: mockDelete,
      ),
      seed: () => CategoryLoaded(categories: [builtIn, custom]),
      act: (bloc) => bloc.add(const DeleteCategory('custom_a')),
      expect: () => [
        CategoryActionLoading(categories: [builtIn, custom]),
        const CategoryError('Gagal menghapus.'),
      ],
    );
  });
}
