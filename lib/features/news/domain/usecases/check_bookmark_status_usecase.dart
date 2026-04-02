import 'package:news_app/features/news/domain/repositories/news_repository.dart';

class CheckBookmarkStatusUseCase {
  final NewsRepository repository;
  CheckBookmarkStatusUseCase(this.repository);

  Future<bool> call(String slug) {
    return repository.isBookmarked(slug);
  }
}
