import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/features/news/data/datasources/news_local_datasource.dart';
import 'package:news_app/features/news/data/models/news_models.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late NewsLocalDatasourceImpl datasource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    datasource = NewsLocalDatasourceImpl(sharedPreferences: mockSharedPreferences);
  });

  const tBookmarksKey = 'BOOKMARKED_ARTICLES';

  final tArticleModel = ArticleModel(
    id: 1,
    categoryId: 2,
    categoryName: 'Tech',
    authorName: 'Admin',
    title: 'Test Article',
    slug: 'test-article',
    description: 'Desc',
    imageUrl: 'img.jpg',
    readTimeMinutes: 5,
    status: 'published',
  );

  group('getBookmarks', () {
    test('harus mengembalikan List<Article> ketika data JSON di SharedPreferences valid', () async {
      // Arrange
      final List<Map<String, dynamic>> jsonList = [tArticleModel.toJson()];
      when(() => mockSharedPreferences.getString(tBookmarksKey)).thenReturn(jsonEncode(jsonList));

      // Act
      final result = await datasource.getBookmarks();

      // Assert
      expect(result.length, 1);
      expect(result.first.slug, 'test-article');
      verify(() => mockSharedPreferences.getString(tBookmarksKey)).called(1);
      verifyNoMoreInteractions(mockSharedPreferences);
    });

    test('harus mengembalikan List kosong [] ketika SharedPreferences kosong (null)', () async {
      // Arrange
      when(() => mockSharedPreferences.getString(tBookmarksKey)).thenReturn(null);

      // Act
      final result = await datasource.getBookmarks();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('isBookmarked', () {
    test('harus mengembalikan true jika slug exist di bookmarks', () async {
      final List<Map<String, dynamic>> jsonList = [tArticleModel.toJson()];
      when(() => mockSharedPreferences.getString(tBookmarksKey)).thenReturn(jsonEncode(jsonList));

      final result = await datasource.isBookmarked('test-article');

      expect(result, isTrue);
    });

    test('harus mengembalikan false jika slug tidak ada', () async {
      when(() => mockSharedPreferences.getString(tBookmarksKey)).thenReturn(null);

      final result = await datasource.isBookmarked('test-article');

      expect(result, isFalse);
    });
  });

  group('toggleBookmark', () {
    test('harus MENAMBAHKAN ke list jika artikel belum ada di bookmark', () async {
      // Arrange
      when(() => mockSharedPreferences.getString(tBookmarksKey)).thenReturn(null); // Kosong
      when(() => mockSharedPreferences.setString(tBookmarksKey, any())).thenAnswer((_) async => true);

      // Act
      await datasource.toggleBookmark(tArticleModel);

      // Assert
      final expectedJson = jsonEncode([tArticleModel.toJson()]);
      verify(() => mockSharedPreferences.setString(tBookmarksKey, expectedJson)).called(1);
    });

    test('harus MENGHAPUS dari list jika artikel sudah ada di bookmark', () async {
      // Arrange
      final List<Map<String, dynamic>> jsonList = [tArticleModel.toJson()];
      when(() => mockSharedPreferences.getString(tBookmarksKey)).thenReturn(jsonEncode(jsonList));
      when(() => mockSharedPreferences.setString(tBookmarksKey, any())).thenAnswer((_) async => true);

      // Act
      await datasource.toggleBookmark(tArticleModel);

      // Assert
      final expectedJson = jsonEncode([]); // Menjadi kosong karena dihapus
      verify(() => mockSharedPreferences.setString(tBookmarksKey, expectedJson)).called(1);
    });
  });
}
