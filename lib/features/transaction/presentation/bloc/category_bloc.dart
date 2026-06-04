import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/create_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_categories_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_category_usecase.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({
    required GetCategoriesUseCase getCategories,
    required CreateCategoryUseCase createCategory,
    required UpdateCategoryUseCase updateCategory,
    required DeleteCategoryUseCase deleteCategory,
  })  : _getCategories = getCategories,
        _createCategory = createCategory,
        _updateCategory = updateCategory,
        _deleteCategory = deleteCategory,
        super(const CategoryInitial()) {
    on<LoadCategories>(_onLoad, transformer: droppable());
    on<CreateCategory>(_onCreate, transformer: sequential());
    on<UpdateCategory>(_onUpdate, transformer: sequential());
    on<DeleteCategory>(_onDelete, transformer: sequential());
  }

  final GetCategoriesUseCase _getCategories;
  final CreateCategoryUseCase _createCategory;
  final UpdateCategoryUseCase _updateCategory;
  final DeleteCategoryUseCase _deleteCategory;

  List<CategoryEntity> get _currentCategories {
    if (state is CategoryLoaded) return (state as CategoryLoaded).categories;
    if (state is CategoryActionLoading) {
      return (state as CategoryActionLoading).categories;
    }
    return const [];
  }

  Future<void> _onLoad(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    final result = await _getCategories(const NoParams());
    result.fold(
      (f) => emit(CategoryError(f.message)),
      (cats) => emit(CategoryLoaded(categories: cats)),
    );
  }

  Future<void> _onCreate(
    CreateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final current = _currentCategories;
    emit(CategoryActionLoading(categories: current));

    final maxSort = current
        .where((c) => !c.isBuiltIn)
        .map((c) => c.sortOrder)
        .fold(90, max);
    final entityWithSort = event.category.copyWith(sortOrder: maxSort + 10);

    final result = await _createCategory(entityWithSort);
    await result.fold(
      (f) async => emit(CategoryError(f.message)),
      (_) async => _reloadWith(emit, successType: CategorySuccessType.created),
    );
  }

  Future<void> _onUpdate(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final current = _currentCategories;
    emit(CategoryActionLoading(categories: current));

    final result = await _updateCategory(event.category);
    await result.fold(
      (f) async => emit(CategoryError(f.message)),
      (_) async => _reloadWith(emit, successType: CategorySuccessType.updated),
    );
  }

  Future<void> _onDelete(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final current = _currentCategories;
    final category = current.where((c) => c.slug == event.slug).firstOrNull;
    if (category == null) return;

    emit(CategoryActionLoading(categories: current));

    final result = await _deleteCategory(
      DeleteCategoryParams(slug: event.slug, isBuiltIn: category.isBuiltIn),
    );
    await result.fold(
      (f) async => emit(CategoryError(f.message)),
      (_) async => _reloadWith(emit, successType: CategorySuccessType.deleted),
    );
  }

  Future<void> _reloadWith(
    Emitter<CategoryState> emit, {
    CategorySuccessType? successType,
  }) async {
    final result = await _getCategories(const NoParams());
    result.fold(
      (f) => emit(CategoryError(f.message)),
      (cats) => emit(CategoryLoaded(categories: cats, successType: successType)),
    );
  }
}
