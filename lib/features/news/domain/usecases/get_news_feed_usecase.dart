import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';

class GetNewsFeedParams {
  final String? category;
  final int page;
  final int limit;
  final bool includeHero;

  const GetNewsFeedParams({
    this.category,
    this.page = 1,
    this.limit = 10,
    this.includeHero = true,
  });
}

class GetNewsFeedUseCase {
  final NewsRepository repository;
  GetNewsFeedUseCase(this.repository);

  Future<({Article? hero, List<Article> feed, int totalPages})> call(GetNewsFeedParams params) {
    return repository.getFeed(
      category: params.category,
      page: params.page,
      limit: params.limit,
      includeHero: params.includeHero,
    );
  }
}
