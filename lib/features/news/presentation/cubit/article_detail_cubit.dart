import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_article_usecase.dart';
import 'package:news_app/features/news/domain/usecases/check_bookmark_status_usecase.dart';
import 'package:news_app/features/news/domain/usecases/toggle_bookmark_usecase.dart';
import 'package:equatable/equatable.dart';

abstract class ArticleDetailState extends Equatable {
  const ArticleDetailState();
  @override
  List<Object?> get props => [];
}

class ArticleDetailInitial extends ArticleDetailState {}

class ArticleDetailLoading extends ArticleDetailState {}

class ArticleDetailLoaded extends ArticleDetailState {
  final Article article;
  final bool isBookmarked;
  const ArticleDetailLoaded(this.article, {this.isBookmarked = false});

  ArticleDetailLoaded copyWith({Article? article, bool? isBookmarked}) {
    return ArticleDetailLoaded(
      article ?? this.article,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  List<Object?> get props => [article, isBookmarked];
}

class ArticleDetailError extends ArticleDetailState {
  final String message;
  const ArticleDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class ArticleDetailCubit extends Cubit<ArticleDetailState> {
  final GetArticleUseCase _getArticleUseCase;
  final CheckBookmarkStatusUseCase _checkBookmarkUseCase;
  final ToggleBookmarkUseCase _toggleBookmarkUseCase;

  ArticleDetailCubit(
    this._getArticleUseCase,
    this._checkBookmarkUseCase,
    this._toggleBookmarkUseCase,
  ) : super(ArticleDetailInitial());

  Future<void> loadArticle(String slug) async {
    emit(ArticleDetailLoading());
    try {
      final article = await _getArticleUseCase(slug);
      final isBookmarked = await _checkBookmarkUseCase(slug);
      emit(ArticleDetailLoaded(article, isBookmarked: isBookmarked));
    } catch (e) {
      emit(ArticleDetailError(e.toString()));
    }
  }

  Future<void> toggleBookmark() async {
    final currentState = state;
    if (currentState is ArticleDetailLoaded) {
      // Optimistic update
      final newStatus = !currentState.isBookmarked;
      emit(currentState.copyWith(isBookmarked: newStatus));

      try {
        await _toggleBookmarkUseCase(currentState.article);
      } catch (e) {
        // Revert on failure
        emit(currentState.copyWith(isBookmarked: !newStatus));
      }
    }
  }
}
