import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/features/news/domain/entities/article.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK ENTITIY (NEWS FEATURE)
// =============================================================================
// Kita tidak perlu tes getter/setter biasa, tetapi Article memiliki Getter Logic
// seperti getters "displayImage" dan "timeAgo" yang melakukan kalkulasi.
// Itu wajib di-test.
// =============================================================================

void main() {
  group('Article Entity', () {
    Article createMockArticle({
      DateTime? publishedAt,
      String imageUrl = 'full.jpg',
      String? thumbnailUrl,
    }) {
      return Article(
        id: 1,
        categoryId: 1,
        categoryName: 'Tech',
        authorName: 'Nunu',
        title: 'Title',
        slug: 'slug',
        description: 'desc',
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
        readTimeMinutes: 5,
        status: 'published',
        publishedAt: publishedAt,
      );
    }

    group('displayImage', () {
      test('harus return thumbnailUrl jika tersedia', () {
        final article = createMockArticle(
          imageUrl: 'full.jpg',
          thumbnailUrl: 'thumb.jpg',
        );
        expect(article.displayImage, 'thumb.jpg');
      });

      test('harus fallback ke imageUrl jika thumbnailUrl null', () {
        final article = createMockArticle(
          imageUrl: 'full.jpg',
          thumbnailUrl: null, // null
        );
        expect(article.displayImage, 'full.jpg');
      });
    });



    group('Equatable props', () {
      test('harus menganggap setara jika id dan slug sama', () {
        final a1 = createMockArticle();
        // create instance kedua yang mirip tapi beda instance
        final a2 = Article(
          id: 1, // sama
          categoryId: 2, // beda
          categoryName: 'Beda',
          authorName: 'Beda',
          title: 'Beda',
          slug: 'slug', // sama
          description: 'desc',
          imageUrl: 'img',
          readTimeMinutes: 5,
          status: 'published',
        );

        // Hanya peduli id dan slug, harusnya equal true
        expect(a1 == a2, isTrue);
      });
    });
  });
}
