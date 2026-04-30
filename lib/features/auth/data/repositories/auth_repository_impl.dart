import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:news_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:news_app/features/auth/data/models/user_model.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/core/utils/repository_helper.dart';
import 'package:news_app/features/auth/domain/services/firebase_otp_service.dart';
import 'package:news_app/features/auth/domain/services/oauth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDatasource localDatasource;
  final FirebaseOTPService firebaseOtpService;

  AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.firebaseOtpService,
  });

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return RepositoryHelper.execute(() async {
      return await remoteDatasource.register(
        name: name,
        email: email,
        password: password,
      );
    });
  }

  @override
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    return RepositoryHelper.execute(() async {
      final tokens = await remoteDatasource.login(
        email: email,
        password: password,
      );

      // Save tokens locally
      await localDatasource.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      return tokens;
    });
  }

  @override
  Future<Either<Failure, AuthTokens>> signInWithOAuth(OAuthService service) async {
    return RepositoryHelper.execute(() async {
      // 1. Get token from the provider (e.g. Google SDK popup)
      final idToken = await service.signIn();

      // 2. Exchange token with our backend
      final tokens = await remoteDatasource.signInWithOAuth(
        provider: service.providerName,
        idToken: idToken,
      );

      // 3. Save tokens locally
      await localDatasource.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      return tokens;
    });
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final user = await remoteDatasource.getProfile();

      // Cache profile locally
      // Cache profile locally
      await localDatasource.cacheProfile(
        id: user.id,
        name: user.name,
        email: user.email,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        phone: user.phone,
        preferences: user.preferences,
      );

      return Right(user);
    } on ServerException catch (e) {
      // Try cached profile as fallback
      final cached = await localDatasource.getCachedProfile();
      if (cached != null) {
        return Right(User(
          id: cached['id'] as int,
          name: cached['name'] as String,
          email: cached['email'] as String,
          avatarUrl: cached['avatarUrl'] as String? ?? '',
          bio: cached['bio'] as String? ?? '',
          phone: cached['phone'] as String? ?? '',
          preferences: cached['preferences'] as String? ?? '',
        ));
      }
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      // Try cached profile as fallback
      final cached = await localDatasource.getCachedProfile();
      if (cached != null) {
        return Right(User(
          id: cached['id'] as int,
          name: cached['name'] as String,
          email: cached['email'] as String,
          avatarUrl: cached['avatarUrl'] as String? ?? '',
          bio: cached['bio'] as String? ?? '',
          phone: cached['phone'] as String? ?? '',
          preferences: cached['preferences'] as String? ?? '',
        ));
      }
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(User user) async {
    return RepositoryHelper.execute(() async {
      // Cast the entity back to a model (or create one on the fly)
      final userModel = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        phone: user.phone,
        preferences: user.preferences,
      );

      final updatedUser = await remoteDatasource.updateProfile(userModel);

      // Refresh cache profile locally
      await localDatasource.cacheProfile(
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        avatarUrl: updatedUser.avatarUrl,
        bio: updatedUser.bio,
        phone: updatedUser.phone,
        preferences: updatedUser.preferences,
      );

      return updatedUser;
    });
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await localDatasource.getRefreshToken();
      if (refreshToken != null) {
        await remoteDatasource.logout(refreshToken: refreshToken);
      }
      await localDatasource.clearAll();
      return const Right(null);
    } on ServerException catch (_) {
      // Even if server logout fails, clear everything locally
      await localDatasource.clearAll();
      return const Right(null);
    } on NetworkException catch (_) {
      // Disconnected during logout? Still clear locale
      await localDatasource.clearAll();
      return const Right(null);
    } catch (_) {
      await localDatasource.clearAll();
      return const Right(null);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await localDatasource.hasTokens();
  }

  @override
  Future<Either<Failure, String>> requestOTP({required String phoneNumber}) async {
    return await firebaseOtpService.requestOTP(phoneNumber);
  }

  @override
  Future<Either<Failure, String>> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    return await firebaseOtpService.verifyOTP(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String firebaseIdToken,
    required String newPassword,
  }) async {
    try {
      await remoteDatasource.resetPasswordForgot(
        firebaseIdToken: firebaseIdToken,
        newPassword: newPassword,
      );
      
      // Clear local tokens to force relogin
      await localDatasource.clearAll();
      
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
