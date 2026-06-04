part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {
  const LoadCategories();
}

class CreateCategory extends CategoryEvent {
  const CreateCategory(this.category);
  final CategoryEntity category;
  @override
  List<Object?> get props => [category];
}

class UpdateCategory extends CategoryEvent {
  const UpdateCategory(this.category);
  final CategoryEntity category;
  @override
  List<Object?> get props => [category];
}

class DeleteCategory extends CategoryEvent {
  const DeleteCategory(this.slug);
  final String slug;
  @override
  List<Object?> get props => [slug];
}
