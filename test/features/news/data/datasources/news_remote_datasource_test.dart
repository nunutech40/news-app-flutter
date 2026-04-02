import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/network/api_client.dart';
import 'package:news_app/features/news/data/datasources/news_remote_datasource.dart';
import 'package:news_app/features/news/data/models/news_models.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK REMOTE DATASOURCE (NEWS FEATURE)
// =============================================================================
// Datasource adalah "Gerbang Jaringan" yang tugasnya:
// 1. Memanggil ApiClient dengan method + path + parameter yang TEPAT.
// 2. Memetakan (parsing) raw JSON response menjadi Model yang type-safe.
//
// FOKUS TEST:
// - Jangan test logika HTTP/500 di sini — itu tugas ApiClient.
// - Test HANYA memastikan:
//   a. Happy Path: JSON valid → Model/List yang benar.
//   b. Error Path: ApiClient melempar ServerException → datasource meneruskannya (re-throw).
//   c. Edge Path: JSON tidak lengkap, field null, list kosong, dll.
// =============================================================================

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late NewsRemoteDatasourceImpl datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = NewsRemoteDatasourceImpl(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // getCategories()
  // ---------------------------------------------------------------------------
  group('getCategories', () {
    final tCategoriesJson = {
      'success': true,
      'data': [
        {'id': 1, 'name': 'Technology', 'slug': 'technology', 'description': 'Tech news', 'is_active': true},
        {'id': 2, 'name': 'Sports', 'slug': 'sports', 'description': 'Sports news', 'is_active': true},
      ],
    };

    // ----- HAPPY PATH -----
    test('harus mengembalikan List<CategoryModel> saat response JSON valid', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any()))
          .thenAnswer((_) async => tCategoriesJson);

      // Act
      final result = await datasource.getCategories();

      // Assert
      expect(result, isA<List<CategoryModel>>());
      expect(result.length, 2);
      expect(result.first.name, 'Technology');
      expect(result.last.slug, 'sports');
      verify(() => mockApiClient.request('GET', ApiConstants.newsCategories)).called(1);
    });

    // ----- EDGE PATH: LIST KOSONG -----
    test('harus mengembalikan list kosong [] jika data dari server memang tidak ada kategori', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any()))
          .thenAnswer((_) async => {'success': true, 'data': []});

      // Act
      final result = await datasource.getCategories();

      // Assert
      expect(result, isEmpty);
    });

    // ----- ERROR PATH -----
    test('harus melempar kembali ServerException jika ApiClient gagal menjangkau server', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any()))
          .thenThrow(const ServerException(message: 'Connection timeout'));

      // Act
      final call = datasource.getCategories();

      // Assert
      expect(() => call, throwsA(isA<ServerException>()));
    });
  });

  // ---------------------------------------------------------------------------
  // getFeed()
  // ---------------------------------------------------------------------------
  group('getFeed', () {
    final tFeedDataMap = {
      'hero': {
        'id': 99,
        'category_id': 1,
        'title': 'Hero Article',
        'slug': 'hero-article',
        'image_url': 'img.jpg',
        'category_name': 'Technology',
        'author_name': 'Nunu',
        'description': 'Desc',
        'read_time_minutes': 5,
        'status': 'published',
      },
      'articles': [],
    };

    final tFeedJson = {'success': true, 'data': tFeedDataMap};

    // ----- HAPPY PATH (DEFAULT PARAMS) -----
    test('harus mengembalikan Map data feed dengan query param default saat tidak ada filter', () async {
      // Arrange
      when(() => mockApiClient.request(
            any(),
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => tFeedJson);

      // Act
      final result = await datasource.getFeed();

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('hero'), isTrue);
      verify(() => mockApiClient.request(
            'GET',
            ApiConstants.newsFeed,
            queryParameters: {
              'page': 1,
              'limit': 10,
              'include_hero': true,
            },
          )).called(1);
    });

    // ----- HAPPY PATH (DENGAN FILTER KATEGORI) -----
    test('harus menyertakan key "category" pada query params saat filter kategori diberikan', () async {
      // Arrange
      when(() => mockApiClient.request(
            any(),
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => tFeedJson);

      // Act
      await datasource.getFeed(category: 'technology', page: 2, limit: 5);

      // Assert: pastikan query params yang dikirim ke ApiClient mengandung kategori
      verify(() => mockApiClient.request(
            'GET',
            ApiConstants.newsFeed,
            queryParameters: {
              'page': 2,
              'limit': 5,
              'include_hero': true,
              'category': 'technology',
            },
          )).called(1);
    });

    // ----- EDGE PATH: TANPA HERO (INCLUDE_HERO = FALSE) -----
    test('harus mengirim include_hero: false ke query params saat diminta tanpa hero', () async {
      // Arrange
      when(() => mockApiClient.request(
            any(),
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => {'success': true, 'data': {'articles': []}});

      // Act
      await datasource.getFeed(includeHero: false);

      // Assert
      verify(() => mockApiClient.request(
            'GET',
            ApiConstants.newsFeed,
            queryParameters: {
              'page': 1,
              'limit': 10,
              'include_hero': false,
            },
          )).called(1);
    });

    // ----- ERROR PATH -----
    test('harus melempar ServerException jika server mengembalikan error', () async {
      // Arrange
      when(() => mockApiClient.request(
            any(),
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(const ServerException(message: 'Internal Server Error'));

      // Act
      final call = datasource.getFeed();

      // Assert
      expect(() => call, throwsA(isA<ServerException>()));
    });
  });

  // ---------------------------------------------------------------------------
  // getArticle(slug)
  // ---------------------------------------------------------------------------
  group('getArticle', () {
    const tSlug = 'flutter-is-great-2026';
    final tArticleJson = {
      'success': true,
      'data': {
        'id': 42,
        'category_id': 1,
        'category_name': 'Technology',
        'author_name': 'Nunu Dev',
        'title': 'Flutter is Great',
        'slug': tSlug,
        'description': 'Short description',
        'content': 'Full content here...',
        'image_url': 'https://cdn.example.com/img.jpg',
        'thumbnail_url': null,
        'read_time_minutes': 4,
        'status': 'published',
        'published_at': '2026-04-02T00:00:00Z',
      }
    };

    // ----- HAPPY PATH -----
    test('harus mengembalikan ArticleModel dengan data lengkap saat slug ditemukan di server', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any()))
          .thenAnswer((_) async => tArticleJson);

      // Act
      final result = await datasource.getArticle(tSlug);

      // Assert
      expect(result, isA<ArticleModel>());
      expect(result.slug, tSlug);
      expect(result.title, 'Flutter is Great');
      expect(result.readTimeMinutes, 4);
      expect(result.thumbnailUrl, isNull);
      // Pastikan endpoint yang dipanggil mengandung slug
      verify(() => mockApiClient.request('GET', '${ApiConstants.newsDetail}/$tSlug')).called(1);
    });

    // ----- EDGE PATH: publishedAt NULL -----
    test('harus tetap parse ArticleModel dengan publishedAt null tanpa crash', () async {
      // Arrange: server mengirim artikel tanpa tanggal publikasi
      final jsonWithoutDate = Map<String, dynamic>.from(tArticleJson);
      (jsonWithoutDate['data'] as Map<String, dynamic>)['published_at'] = null;

      when(() => mockApiClient.request(any(), any()))
          .thenAnswer((_) async => jsonWithoutDate);

      // Act
      final result = await datasource.getArticle(tSlug);

      // Assert: tidak crash dan publishedAt memang null
      expect(result.publishedAt, isNull);
    });

    // ----- ERROR PATH: SLUG TIDAK ADA (404) -----
    test('harus melempar ServerException saat slug artikel tidak ditemukan di server', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any()))
          .thenThrow(const ServerException(message: 'Article not found', statusCode: 404));

      // Act
      final call = datasource.getArticle('slug-yang-tidak-ada');

      // Assert
      expect(
        () => call,
        throwsA(isA<ServerException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });
  });
}
