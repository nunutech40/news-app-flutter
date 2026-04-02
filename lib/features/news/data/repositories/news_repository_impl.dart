import 'package:news_app/features/news/data/datasources/news_remote_datasource.dart';
import 'package:news_app/features/news/data/models/news_models.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/entities/category.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDatasource remoteDatasource;

  NewsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<Category>> getCategories() => remoteDatasource.getCategories();

  @override
  Future<({Article? hero, List<Article> feed, int totalPages})> getFeed({
    String? category,
    int page = 1,
    int limit = 10,
    bool includeHero = true,
  }) async {
    final data = await remoteDatasource.getFeed(
      category: category,
      page: page,
      limit: limit,
      includeHero: includeHero,
    );

    Article? hero;
    if (data['hero_article'] != null) {
      hero = ArticleModel.fromJson(data['hero_article'] as Map<String, dynamic>);
    }

    final feedRaw = data['feed_articles'] as List<dynamic>? ?? [];
    final feed = feedRaw
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final totalPages = meta['total_pages'] as int? ?? 1;

    return (hero: hero, feed: feed, totalPages: totalPages);
  }

  @override
  Future<Article> getArticle(String slug) => remoteDatasource.getArticle(slug);
}
