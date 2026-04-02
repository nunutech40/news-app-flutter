import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/data/datasources/news_remote_datasource.dart';
import 'package:news_app/features/news/data/models/news_models.dart';
import 'package:news_app/features/news/data/repositories/news_repository_impl.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/entities/category.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK REPOSITORY (NEWS FEATURE)
// =============================================================================
// NewsRepository berbeda dengan AuthRepository karena:
// 1. Ia TIDAK menggunakan Either<Failure, T> — error dibiarkan propagate naik
//    (Cubit yang tangkap via try/catch).
// 2. getFeed() berperan sebagai "Orchestrator": menerima raw Map dari datasource
//    lalu memetakan JSON ke domain entities (Article) dan merakit response
//    menjadi Record type Dart modern: ({hero, feed, totalPages}).
//
// SKENARIO WAJIB:
//   a. Happy Path (Delegasi): getCategories() dan getArticle() mendelegasikan
//      langsung ke datasource — pastikan hasilnya diteruskan tanpa modifikasi.
//   b. Happy Path (Orkestrasi getFeed): Data JSON dengan hero_article lengkap
//      diparsing menjadi Article entity dan dibungkus dalam Record.
//   c. Edge Path getFeed: 
//      - Tidak ada hero (null) → field hero di Record harus null.
//      - feed_articles kosong → feed di Record harus [].
//      - meta tidak ada → totalPages default ke 1.
//   d. Error Path: Exception dari datasource naik tanpa ditangkap repository.
// =============================================================================

class MockNewsRemoteDatasource extends Mock implements NewsRemoteDatasource {}

// Fake untuk fallback Mocktail ketika pakai any() dengan tipe custom
class FakeCategoryModel extends Fake implements CategoryModel {}
class FakeArticleModel extends Fake implements ArticleModel {}

void main() {
  late NewsRepositoryImpl repository;
  late MockNewsRemoteDatasource mockDatasource;

  setUpAll(() {
    registerFallbackValue(FakeCategoryModel());
    registerFallbackValue(FakeArticleModel());
  });

  setUp(() {
    mockDatasource = MockNewsRemoteDatasource();
    repository = NewsRepositoryImpl(remoteDatasource: mockDatasource);
  });

  // ---------------------------------------------------------------------------
  // getCategories() — simple delegation
  // ---------------------------------------------------------------------------
  group('getCategories', () {
    final tCategories = [
      const CategoryModel(id: 1, name: 'Technology', slug: 'technology', description: '', isActive: true),
      const CategoryModel(id: 2, name: 'Sports', slug: 'sports', description: '', isActive: true),
    ];

    test('harus mendelegasikan pemanggilan dan meneruskan List<Category> dari datasource', () async {
      // Arrange
      when(() => mockDatasource.getCategories()).thenAnswer((_) async => tCategories);

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result, isA<List<Category>>());
      expect(result.length, 2);
      expect(result.first.slug, 'technology');
      verify(() => mockDatasource.getCategories()).called(1);
      verifyNoMoreInteractions(mockDatasource);
    });

    test('harus melempar kembali Exception jika datasource gagal', () async {
      // Arrange
      when(() => mockDatasource.getCategories()).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(() => repository.getCategories(), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // getFeed() — orchestration + JSON mapping
  // ---------------------------------------------------------------------------
  group('getFeed', () {
    // ----- HAPPY PATH: FEED LENGKAP DENGAN HERO -----
    test('harus mem-parsing hero_article dan feed_articles dari Map menjadi Record entity', () async {
      // Arrange: datasource menghasilkan Map mentah seperti yang dikembalikan API
      final tHeroMap = {
        'id': 99,
        'category_id': 1,
        'category_name': 'Technology',
        'author_name': 'Nunu',
        'title': 'Hero Article',
        'slug': 'hero-article',
        'description': 'Hero desc',
        'image_url': 'hero.jpg',
        'read_time_minutes': 5,
        'status': 'published',
        'published_at': '2026-04-02T00:00:00Z',
      };
      final tFeedMap = [
        {
          'id': 1,
          'category_id': 1,
          'category_name': 'Technology',
          'author_name': 'Nunu',
          'title': 'Article 1',
          'slug': 'article-1',
          'description': 'Desc 1',
          'image_url': 'img1.jpg',
          'read_time_minutes': 3,
          'status': 'published',
        },
      ];

      when(() => mockDatasource.getFeed(
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            includeHero: any(named: 'includeHero'),
          )).thenAnswer((_) async => {
                'hero_article': tHeroMap,
                'feed_articles': tFeedMap,
                'meta': {'total_pages': 5},
              });

      // Act
      final result = await repository.getFeed();

      // Assert: hero ada dan terparse dengan benar
      expect(result.hero, isA<Article>());
      expect(result.hero?.slug, 'hero-article');

      // feed terisi satu artikel
      expect(result.feed.length, 1);
      expect(result.feed.first.slug, 'article-1');

      // meta totalPages terbaca
      expect(result.totalPages, 5);
    });

    // ----- EDGE PATH: TANPA HERO (hero_article = null) -----
    test('harus mengembalikan hero null jika key hero_article tidak ada di response', () async {
      // Arrange: hero tidak ada sama sekali dari server
      when(() => mockDatasource.getFeed(
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            includeHero: any(named: 'includeHero'),
          )).thenAnswer((_) async => {
                'hero_article': null, // Tidak ada hero
                'feed_articles': [],
                'meta': {'total_pages': 1},
              });

      // Act
      final result = await repository.getFeed();

      // Assert
      expect(result.hero, isNull);
      expect(result.feed, isEmpty);
    });

    // ----- EDGE PATH: feed_articles KEY TIDAK ADA (Server Response Parsial) -----
    test('harus mengembalikan feed kosong [] jika key feed_articles tidak ada di response', () async {
      // Arrange: response tidak menyertakan key feed_articles sama sekali
      when(() => mockDatasource.getFeed(
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            includeHero: any(named: 'includeHero'),
          )).thenAnswer((_) async => {
                // Tidak ada key 'feed_articles' maupun 'meta'
              });

      // Act
      final result = await repository.getFeed();

      // Assert: tidak crash, fallback ke [] dan totalPages 1
      expect(result.feed, isEmpty);
      expect(result.totalPages, 1);
    });

    // ----- EDGE PATH: meta TIDAK ADA → totalPages default 1 -----
    test('harus mengembalikan totalPages = 1 jika key meta tidak ada', () async {
      // Arrange
      when(() => mockDatasource.getFeed(
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            includeHero: any(named: 'includeHero'),
          )).thenAnswer((_) async => {
                'feed_articles': [],
                // Tidak ada 'meta'
              });

      // Act
      final result = await repository.getFeed();

      // Assert
      expect(result.totalPages, 1);
    });

    // ----- ERROR PATH -----
    test('harus melempar kembali Exception jika datasource getFeed gagal', () async {
      // Arrange
      when(() => mockDatasource.getFeed(
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            includeHero: any(named: 'includeHero'),
          )).thenThrow(Exception('Server 500'));

      // Act & Assert
      expect(() => repository.getFeed(), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // getArticle(slug) — simple delegation
  // ---------------------------------------------------------------------------
  group('getArticle', () {
    const tSlug = 'flutter-is-great';
    final tArticleModel = ArticleModel(
      id: 42,
      categoryId: 1,
      categoryName: 'Technology',
      authorName: 'Nunu',
      title: 'Flutter is Great',
      slug: tSlug,
      description: 'Short desc',
      imageUrl: 'img.jpg',
      readTimeMinutes: 4,
      status: 'published',
    );

    test('harus mendelegasikan ke datasource dan meneruskan Article entity tanpa modifikasi', () async {
      // Arrange
      when(() => mockDatasource.getArticle(any())).thenAnswer((_) async => tArticleModel);

      // Act
      final result = await repository.getArticle(tSlug);

      // Assert
      expect(result, isA<Article>());
      expect(result.slug, tSlug);
      expect(result.title, 'Flutter is Great');
      verify(() => mockDatasource.getArticle(tSlug)).called(1);
      verifyNoMoreInteractions(mockDatasource);
    });

    test('harus melempar Exception jika artikel dengan slug tersebut tidak ditemukan', () async {
      // Arrange
      when(() => mockDatasource.getArticle(any())).thenThrow(Exception('404 not found'));

      // Act & Assert
      expect(() => repository.getArticle('slug-palsu'), throwsException);
    });
  });
}
