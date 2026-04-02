import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_article_usecase.dart';
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
  const ArticleDetailLoaded(this.article);

  @override
  List<Object?> get props => [article];
}

class ArticleDetailError extends ArticleDetailState {
  final String message;
  const ArticleDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class ArticleDetailCubit extends Cubit<ArticleDetailState> {
  final GetArticleUseCase _useCase;

  ArticleDetailCubit(this._useCase) : super(ArticleDetailInitial());

  Future<void> loadArticle(String slug) async {
    emit(ArticleDetailLoading());
    try {
      final article = await _useCase(slug);
      emit(ArticleDetailLoaded(article));
    } catch (e) {
      emit(ArticleDetailError(e.toString()));
    }
  }
}
