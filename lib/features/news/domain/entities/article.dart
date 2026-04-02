import 'package:equatable/equatable.dart';

class Article extends Equatable {
  final int id;
  final int categoryId;
  final String categoryName;
  final String authorName;
  final String title;
  final String slug;
  final String description; // short teaser shown in list/card
  final String? content;   // full body, only present in detail endpoint
  final String imageUrl;
  final String? thumbnailUrl;
  final int readTimeMinutes;
  final String status;
  final DateTime? publishedAt;

  const Article({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.authorName,
    required this.title,
    required this.slug,
    required this.description,
    this.content,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.readTimeMinutes,
    required this.status,
    this.publishedAt,
  });

  /// Convenience getter — use thumbnail for lists, full image for detail
  String get displayImage => thumbnailUrl ?? imageUrl;



  @override
  List<Object?> get props => [id, slug];
}
