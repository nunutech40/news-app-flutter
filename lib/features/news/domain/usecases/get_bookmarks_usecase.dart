import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';

class GetBookmarksUseCase {
  final NewsRepository repository;
  GetBookmarksUseCase(this.repository);

  Future<List<Article>> call() {
    return repository.getBookmarks();
  }
}
