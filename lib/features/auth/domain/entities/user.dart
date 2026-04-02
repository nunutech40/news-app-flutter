import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String avatarUrl;
  final String bio;
  final String phone;
  final String preferences;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.bio = '',
    this.phone = '',
    this.preferences = '',
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, email, avatarUrl, bio, phone, preferences, createdAt];
}
