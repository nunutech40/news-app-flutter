import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';

// ── State ─────────────────────────────────────────────────────────────────────
abstract class NewsFeedState extends Equatable {
  const NewsFeedState();
  @override
  List<Object?> get props => [];
}

class NewsFeedInitial extends NewsFeedState {}
class NewsFeedLoading extends NewsFeedState {}

class NewsFeedLoaded extends NewsFeedState {
  final Article? hero;
  final List<Article> feed;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  const NewsFeedLoaded({
    this.hero,
    required this.feed,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < totalPages;

  NewsFeedLoaded copyWith({
    Article? hero,
    List<Article>? feed,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return NewsFeedLoaded(
      hero: hero ?? this.hero,
      feed: feed ?? this.feed,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [hero, feed, currentPage, totalPages, isLoadingMore];
}

class NewsFeedError extends NewsFeedState {
  final String message;
  const NewsFeedError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class NewsFeedCubit extends Cubit<NewsFeedState> {
  final GetNewsFeedUseCase _useCase;

  NewsFeedCubit(this._useCase) : super(NewsFeedInitial());

  Future<void> load({String? category}) async {
    emit(NewsFeedLoading());
    try {
      final result = await _useCase(GetNewsFeedParams(
        category: category,
        page: 1,
        limit: 10,
        includeHero: true,
      ));
      emit(NewsFeedLoaded(
        hero: result.hero,
        feed: result.feed,
        currentPage: 1,
        totalPages: result.totalPages,
      ));
    } catch (e) {
      emit(NewsFeedError(e.toString()));
    }
  }

  /// Append next page — for infinite scroll
  Future<void> loadMore({String? category}) async {
    final current = state;
    if (current is! NewsFeedLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final result = await _useCase(GetNewsFeedParams(
        category: category,
        page: nextPage,
        limit: 10,
        includeHero: false,
      ));
      emit(current.copyWith(
        feed: [...current.feed, ...result.feed],
        currentPage: nextPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh({String? category}) => load(category: category);
}
