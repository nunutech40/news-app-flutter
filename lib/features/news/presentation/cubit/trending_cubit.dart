import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/core/utils/exception_mapper.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';

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
  final GetNewsFeedUseCase _useCase;

  TrendingCubit(this._useCase) : super(TrendingLoading());

  Future<void> load() async {
    emit(TrendingLoading());
    try {
      final result = await _useCase(const GetNewsFeedParams(
        category: 'technology',
        limit: 5,
        includeHero: false,
      ));
      await Future.delayed(const Duration(milliseconds: 1000));
      if (isClosed) return;
      emit(TrendingLoaded(articles: result.feed));
    } catch (e) {
      emit(TrendingError(ExceptionMapper.toMessage(e)));
    }
  }
}
