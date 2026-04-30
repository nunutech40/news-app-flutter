import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/services/oauth_service.dart';

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

  /// Login with an OAuth provider
  Future<Either<Failure, AuthTokens>> signInWithOAuth(OAuthService service);

  /// Get current user profile
  Future<Either<Failure, User>> getProfile();

  /// Update user profile
  Future<Either<Failure, User>> updateProfile(User user);

  /// Logout user
  Future<Either<Failure, void>> logout();

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated();

  /// Request OTP for Forgot Password
  Future<Either<Failure, String>> requestOTP({required String phoneNumber});

  /// Reset Password with OTP verification
  Future<Either<Failure, void>> resetPasswordWithOTP({
    required String verificationId,
    required String smsCode,
    required String newPassword,
  });
}
