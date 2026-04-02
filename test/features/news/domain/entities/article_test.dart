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

    group('timeAgo', () {
      test('harus kembalikan string kosong jika publishedAt null', () {
        final article = createMockArticle(publishedAt: null);
        expect(article.timeAgo, '');
      });

      test('harus kembalikan menit jika selisih waktu di bawah 1 jam', () {
        final date = DateTime.now().subtract(const Duration(minutes: 30));
        final article = createMockArticle(publishedAt: date);
        expect(article.timeAgo, '30m ago');
      });

      test('harus kembalikan jam jika selisih waktu di bawah 1 hari', () {
        final date = DateTime.now().subtract(const Duration(hours: 5));
        final article = createMockArticle(publishedAt: date);
        expect(article.timeAgo, '5h ago');
      });

      test('harus kembalikan hari jika selisih waktu lebih dari 24 jam', () {
        final date = DateTime.now().subtract(const Duration(days: 3));
        final article = createMockArticle(publishedAt: date);
        expect(article.timeAgo, '3d ago');
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
