import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';

class ToggleBookmarkUseCase {
  final NewsRepository repository;
  ToggleBookmarkUseCase(this.repository);

  Future<void> call(Article article) {
    return repository.toggleBookmark(article);
  }
}
