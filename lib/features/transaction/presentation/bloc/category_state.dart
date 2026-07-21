part of 'category_bloc.dart';

enum CategorySuccessType { created, updated, deleted }

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

/// State stabil setelah load/mutasi berhasil.
/// [successType] non-null → BlocListener tampilkan snackbar, lalu state tetap ini.
class CategoryLoaded extends CategoryState {
  const CategoryLoaded({required this.categories, this.successType});
  final List<CategoryEntity> categories;
  final CategorySuccessType? successType;

  @override
  List<Object?> get props => [categories, successType];
}

/// State transisi selama operasi CRUD berjalan.
/// [categories] diisi list saat ini agar UI tetap tampil (tidak blank).
class CategoryActionLoading extends CategoryState {
  const CategoryActionLoading({required this.categories});
  final List<CategoryEntity> categories;

  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  const CategoryError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
