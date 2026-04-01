import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, email, createdAt];
}
