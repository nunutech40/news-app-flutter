import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_bookmarks_usecase.dart';

abstract class BookmarkState extends Equatable {
  const BookmarkState();
  @override
  List<Object> get props => [];
}

class BookmarkInitial extends BookmarkState {}

class BookmarkLoading extends BookmarkState {}

class BookmarkLoaded extends BookmarkState {
  final List<Article> articles;
  const BookmarkLoaded(this.articles);

  @override
  List<Object> get props => [articles];
}

class BookmarkError extends BookmarkState {
  final String message;
  const BookmarkError(this.message);

  @override
  List<Object> get props => [message];
}

class BookmarkCubit extends Cubit<BookmarkState> {
  final GetBookmarksUseCase _getBookmarksUseCase;

  BookmarkCubit(this._getBookmarksUseCase) : super(BookmarkInitial());

  Future<void> loadBookmarks() async {
    emit(BookmarkLoading());
    try {
      final bookmarks = await _getBookmarksUseCase();
      emit(BookmarkLoaded(bookmarks));
    } catch (e) {
      emit(BookmarkError(e.toString()));
    }
  }
}
