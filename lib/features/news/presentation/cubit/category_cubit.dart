import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/news/domain/entities/category.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────
abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}
class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  final String selectedSlug; // '' = All
  const CategoryLoaded({required this.categories, this.selectedSlug = ''});

  @override
  List<Object?> get props => [categories, selectedSlug];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class CategoryCubit extends Cubit<CategoryState> {
  final NewsRepository _repo;

  CategoryCubit(this._repo) : super(CategoryInitial());

  Future<void> load() async {
    emit(CategoryLoading());
    try {
      final cats = await _repo.getCategories();
      emit(CategoryLoaded(categories: cats));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  void select(String slug) {
    final current = state;
    if (current is CategoryLoaded) {
      emit(CategoryLoaded(
        categories: current.categories,
        selectedSlug: slug,
      ));
    }
  }
}
