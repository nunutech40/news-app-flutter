import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';

abstract class TrendingState extends Equatable {
  const TrendingState();
  @override
  List<Object?> get props => [];
}

class TrendingLoading extends TrendingState {}

class TrendingLoaded extends TrendingState {
  final List<Article> articles;
  const TrendingLoaded({required this.articles});

  @override
  List<Object?> get props => [articles];
}

class TrendingError extends TrendingState {
  final String message;
  const TrendingError(this.message);
  @override
  List<Object?> get props => [message];
}

class TrendingCubit extends Cubit<TrendingState> {
  final NewsRepository _repo;

  TrendingCubit(this._repo) : super(TrendingLoading());

  Future<void> load() async {
    emit(TrendingLoading());
    try {
      // Kita tembak API news, tapi sengaja kita set:
      // - includeHero: false
      // - category: technology (contoh untuk trending)
      final result = await _repo.getFeed(
        category: 'technology',
        limit: 5,
        includeHero: false,
      );
      emit(TrendingLoaded(articles: result.feed));
    } catch (e) {
      emit(TrendingError(e.toString()));
    }
  }
}
