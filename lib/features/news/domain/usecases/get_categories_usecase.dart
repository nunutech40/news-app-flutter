import 'package:news_app/features/news/domain/entities/category.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';

class GetCategoriesUseCase {
  final NewsRepository repository;
  GetCategoriesUseCase(this.repository);

  Future<List<Category>> call() {
    return repository.getCategories();
  }
}
