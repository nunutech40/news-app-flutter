import 'package:equatable/equatable.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? errorMessage;
  final User? updatedUser;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.errorMessage,
    this.updatedUser,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? errorMessage,
    User? updatedUser,
  }) {
    return ProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage, // We don't preserve old errors intentionally on copy
      updatedUser: updatedUser ?? this.updatedUser,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, updatedUser];
}
