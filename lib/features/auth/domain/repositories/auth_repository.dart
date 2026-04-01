import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  /// Register a new user
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  });

  /// Login with email and password
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  });

  /// Get current user profile
  Future<Either<Failure, User>> getProfile();

  /// Logout user
  Future<Either<Failure, void>> logout();

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated();
}
