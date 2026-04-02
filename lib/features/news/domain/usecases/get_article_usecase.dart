import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';

class GetArticleUseCase {
  final NewsRepository repository;
  GetArticleUseCase(this.repository);

  Future<Article> call(String slug) {
    return repository.getArticle(slug);
  }
}
