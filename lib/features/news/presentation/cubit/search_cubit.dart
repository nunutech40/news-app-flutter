import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';
import 'package:equatable/equatable.dart';

// ── State ──────────────────────────────────────────────────────────────────
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Article> articles;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  const SearchLoaded({
    required this.articles,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < totalPages;

  SearchLoaded copyWith({
    List<Article>? articles,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return SearchLoaded(
      articles: articles ?? this.articles,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [articles, currentPage, totalPages, isLoadingMore];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class SearchCubit extends Cubit<SearchState> {
  final GetNewsFeedUseCase _useCase;
  String _currentQuery = '';

  SearchCubit(this._useCase) : super(SearchInitial());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }
    
    _currentQuery = query;
    emit(SearchLoading());
    try {
      final result = await _useCase(GetNewsFeedParams(
        searchQuery: query,
        page: 1,
        limit: 15,
        includeHero: false,
      ));
      emit(SearchLoaded(
        articles: result.feed,
        currentPage: 1,
        totalPages: result.totalPages,
      ));
    } catch (e) {
      if (_currentQuery == query) {
        emit(SearchError(e.toString()));
      }
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! SearchLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final result = await _useCase(GetNewsFeedParams(
        searchQuery: _currentQuery,
        page: nextPage,
        limit: 15,
        includeHero: false,
      ));
      emit(current.copyWith(
        articles: [...current.articles, ...result.feed],
        currentPage: nextPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }
}
