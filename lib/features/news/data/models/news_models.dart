import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.description,
    required super.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
      );
}

class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.categoryId,
    required super.categoryName,
    required super.authorName,
    required super.title,
    required super.slug,
    required super.description,
    super.content,
    required super.imageUrl,
    super.thumbnailUrl,
    required super.readTimeMinutes,
    required super.status,
    super.publishedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id'] as int,
        categoryId: json['category_id'] as int,
        categoryName: json['category_name'] as String? ?? '',
        authorName: json['author_name'] as String? ?? '',
        title: json['title'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String? ?? '',
        content: json['content'] as String?,
        imageUrl: json['image_url'] as String? ?? '',
        thumbnailUrl: json['thumbnail_url'] as String?,
        readTimeMinutes: json['read_time_minutes'] as int? ?? 1,
        status: json['status'] as String? ?? 'published',
        publishedAt: json['published_at'] != null
            ? DateTime.tryParse(json['published_at'] as String)
            : null,
      );

  factory ArticleModel.fromEntity(Article entity) => ArticleModel(
        id: entity.id,
        categoryId: entity.categoryId,
        categoryName: entity.categoryName,
        authorName: entity.authorName,
        title: entity.title,
        slug: entity.slug,
        description: entity.description,
        content: entity.content,
        imageUrl: entity.imageUrl,
        thumbnailUrl: entity.thumbnailUrl,
        readTimeMinutes: entity.readTimeMinutes,
        status: entity.status,
        publishedAt: entity.publishedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'category_name': categoryName,
        'author_name': authorName,
        'title': title,
        'slug': slug,
        'description': description,
        'content': content,
        'image_url': imageUrl,
        'thumbnail_url': thumbnailUrl,
        'read_time_minutes': readTimeMinutes,
        'status': status,
        'published_at': publishedAt?.toIso8601String(),
      };
}
