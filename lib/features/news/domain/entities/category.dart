import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String description;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, slug];
}
