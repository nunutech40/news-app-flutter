import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/features/news/data/models/news_models.dart';
import 'package:news_app/features/news/domain/entities/article.dart';

abstract class NewsLocalDatasource {
  Future<List<Article>> getBookmarks();
  Future<void> toggleBookmark(Article article);
  Future<bool> isBookmarked(String slug);
}

class NewsLocalDatasourceImpl implements NewsLocalDatasource {
  final SharedPreferences sharedPreferences;

  static const String _bookmarksKey = 'BOOKMARKED_ARTICLES';

  NewsLocalDatasourceImpl({required this.sharedPreferences});

  @override
  Future<List<Article>> getBookmarks() async {
    final jsonString = sharedPreferences.getString(_bookmarksKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => ArticleModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<bool> isBookmarked(String slug) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.slug == slug);
  }

  @override
  Future<void> toggleBookmark(Article article) async {
    final bookmarks = await getBookmarks();
    final index = bookmarks.indexWhere((b) => b.slug == article.slug);

    if (index >= 0) {
      // Remove if exists
      bookmarks.removeAt(index);
    } else {
      // Add if doesn't exist
      bookmarks.add(article);
    }

    final List<Map<String, dynamic>> jsonList = bookmarks
        .map((e) => ArticleModel.fromEntity(e).toJson())
        .toList();

    await sharedPreferences.setString(_bookmarksKey, jsonEncode(jsonList));
  }
}
