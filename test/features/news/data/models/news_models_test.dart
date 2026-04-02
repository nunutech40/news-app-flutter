import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/features/news/data/models/news_models.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/entities/category.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK MODEL (NEWS FEATURE)
// =============================================================================
// Test model sangat krusial untuk memastikan:
// 1. Model adalah subclass dari Entity.
// 2. fromJson() berhasil mengubah Map Map<String, dynamic> menjadi Model yang tepat.
// 3. Fallback default value bekerja saat JSON memiliki field null.
// =============================================================================

void main() {
  group('CategoryModel', () {
    const tCategoryModel = CategoryModel(
      id: 1,
      name: 'Technology',
      slug: 'technology',
      description: 'All about tech',
      isActive: true,
    );

    test('harus merupakan subclass dari Category entity', () {
      expect(tCategoryModel, isA<Category>());
    });

    test('harus return model valid ketika JSON memiliki semua field yang diperlukan', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'name': 'Technology',
        'slug': 'technology',
        'description': 'All about tech',
        'is_active': true,
      };

      // Act
      final result = CategoryModel.fromJson(jsonMap);

      // Assert
      expect(result, equals(tCategoryModel));
    });

    test('harus return fallback defaults (description "", isActive true) jika null', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'id': 2,
        'name': 'Sports',
        'slug': 'sports',
        // description dan is_active dikosongi (diasumsikan null dari server)
      };

      // Act
      final result = CategoryModel.fromJson(jsonMap);

      // Assert
      expect(result.description, '');
      expect(result.isActive, true);
    });
  });

  group('ArticleModel', () {
    final tArticleModel = ArticleModel(
      id: 99,
      categoryId: 1,
      categoryName: 'Tech',
      authorName: 'Nunu',
      title: 'Article Title',
      slug: 'article-title',
      description: 'teaser',
      content: 'full body',
      imageUrl: 'http://img.com',
      thumbnailUrl: 'http://thumb.com',
      readTimeMinutes: 5,
      status: 'published',
      publishedAt: DateTime(2026, 4, 2, 10, 0, 0), // Tanpa format Z, anggap UTC local test
    );

    test('harus merupakan subclass dari Article entity', () {
      expect(tArticleModel, isA<Article>());
    });

    test('harus return model valid untuk JSON lengkap', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'id': 99,
        'category_id': 1,
        'category_name': 'Tech',
        'author_name': 'Nunu',
        'title': 'Article Title',
        'slug': 'article-title',
        'description': 'teaser',
        'content': 'full body',
        'image_url': 'http://img.com',
        'thumbnail_url': 'http://thumb.com',
        'read_time_minutes': 5,
        'status': 'published',
        'published_at': '2026-04-02T10:00:00.000', // Sesuai bentuk constructor
      };

      // Act
      final result = ArticleModel.fromJson(jsonMap);

      // Assert
      expect(result.id, tArticleModel.id);
      expect(result.title, tArticleModel.title);
      expect(result.publishedAt, equals(tArticleModel.publishedAt));
    });

    test('harus memasang default fallback jika atribut opsional bernilai null', () {
      // Arrange: JSON feed biasanya kehilangan banyak detail
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'category_id': 1,
        'title': 'Title Only',
        'slug': 'title-only',
        // yang lain null
      };

      // Act
      final result = ArticleModel.fromJson(jsonMap);

      // Assert: pastikan fallback fallback bekerja
      expect(result.categoryName, '');
      expect(result.authorName, '');
      expect(result.description, '');
      expect(result.imageUrl, '');
      expect(result.readTimeMinutes, 1);
      expect(result.status, 'published');
      expect(result.content, isNull);
      expect(result.thumbnailUrl, isNull);
      expect(result.publishedAt, isNull);
    });

    test('harus melempar TypeError jika field wajib bertipe salah atau null', () {
      // Arrange: id wajib int, tapi dikirim string
      final Map<String, dynamic> jsonMap = {
        'id': 'satu', // ERROR TYPE
        'category_id': 1,
        'title': 'Bad type',
        'slug': 'bad-type',
      };

      // Act & Assert
      expect(() => ArticleModel.fromJson(jsonMap), throwsA(isA<TypeError>()));
    });
  });
}
