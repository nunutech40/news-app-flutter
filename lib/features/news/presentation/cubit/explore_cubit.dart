import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';

enum FetchStatus { initial, loading, loaded, error }

class ExploreState extends Equatable {
  final FetchStatus techStatus;
  final List<Article> techArticles;

  final FetchStatus businessStatus;
  final List<Article> businessArticles;

  final FetchStatus sportsStatus;
  final List<Article> sportsArticles;

  const ExploreState({
    this.techStatus = FetchStatus.initial,
    this.techArticles = const [],
    this.businessStatus = FetchStatus.initial,
    this.businessArticles = const [],
    this.sportsStatus = FetchStatus.initial,
    this.sportsArticles = const [],
  });

  ExploreState copyWith({
    FetchStatus? techStatus,
    List<Article>? techArticles,
    FetchStatus? businessStatus,
    List<Article>? businessArticles,
    FetchStatus? sportsStatus,
    List<Article>? sportsArticles,
  }) {
    return ExploreState(
      techStatus: techStatus ?? this.techStatus,
      techArticles: techArticles ?? this.techArticles,
      businessStatus: businessStatus ?? this.businessStatus,
      businessArticles: businessArticles ?? this.businessArticles,
      sportsStatus: sportsStatus ?? this.sportsStatus,
      sportsArticles: sportsArticles ?? this.sportsArticles,
    );
  }

  @override
  List<Object?> get props => [
        techStatus,
        techArticles,
        businessStatus,
        businessArticles,
        sportsStatus,
        sportsArticles,
      ];
}

class ExploreCubit extends Cubit<ExploreState> {
  final GetNewsFeedUseCase _getNewsFeedUseCase;

  ExploreCubit(this._getNewsFeedUseCase) : super(const ExploreState());

  void loadAllSections() {
    // 1. Emit loading untuk ketiga section secara bersamaan
    emit(state.copyWith(
      techStatus: FetchStatus.loading,
      businessStatus: FetchStatus.loading,
      sportsStatus: FetchStatus.loading,
    ));

    // 2. Fetch Tech (Tidak pakai await agar jalan paralel)
    _getNewsFeedUseCase(const GetNewsFeedParams(
      category: 'technology',
      limit: 5,
      includeHero: false,
    )).then((result) {
      // Simulasi delay tambahan agar nampak transisi UI (Optional tp biar visualnya jelas)
      Future.delayed(const Duration(milliseconds: 600), () {
        if (isClosed) return;
        emit(state.copyWith(
          techStatus: FetchStatus.loaded,
          techArticles: result.feed,
        ));
      });
    }).catchError((_) {
      if (!isClosed) emit(state.copyWith(techStatus: FetchStatus.error));
    });

    // 3. Fetch Business
    _getNewsFeedUseCase(const GetNewsFeedParams(
      category: 'business',
      limit: 5,
      includeHero: false,
    )).then((result) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (isClosed) return;
        emit(state.copyWith(
          businessStatus: FetchStatus.loaded,
          businessArticles: result.feed,
        ));
      });
    }).catchError((_) {
      if (!isClosed) emit(state.copyWith(businessStatus: FetchStatus.error));
    });

    // 4. Fetch Sports
    _getNewsFeedUseCase(const GetNewsFeedParams(
      category: 'sports',
      limit: 5,
      includeHero: false,
    )).then((result) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (isClosed) return;
        emit(state.copyWith(
          sportsStatus: FetchStatus.loaded,
          sportsArticles: result.feed,
        ));
      });
    }).catchError((_) {
      if (!isClosed) emit(state.copyWith(sportsStatus: FetchStatus.error));
    });
  }
}
