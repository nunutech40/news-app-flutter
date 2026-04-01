import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:news_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDatasource localDatasource;

  AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDatasource.register(
        name: name,
        email: email,
        password: password,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokens = await remoteDatasource.login(
        email: email,
        password: password,
      );

      // Save tokens locally
      await localDatasource.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      return Right(tokens);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final user = await remoteDatasource.getProfile();

      // Cache profile locally
      await localDatasource.cacheProfile(
        id: user.id,
        name: user.name,
        email: user.email,
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
        ));
      }
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
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
    } catch (_) {
      await localDatasource.clearAll();
      return const Right(null);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await localDatasource.hasTokens();
  }
}
