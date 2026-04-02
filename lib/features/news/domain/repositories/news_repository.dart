import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/entities/category.dart';

abstract class NewsRepository {
  Future<List<Category>> getCategories();

  Future<({Article? hero, List<Article> feed, int totalPages})> getFeed({
    String? category,
    String? searchQuery,
    int page = 1,
    int limit = 10,
    bool includeHero = true,
  });

  Future<Article> getArticle(String slug);

  // Local Bookmarks
  Future<List<Article>> getBookmarks();
  Future<void> toggleBookmark(Article article);
  Future<bool> isBookmarked(String slug);
}
