import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';

class RepositoryHelper {
  RepositoryHelper._();

  /// Menjalankan fungsi dari datasource dan secara otomatis menangkap
  /// exception untuk diubah menjadi `Failure` (Dartz Either).
  ///
  /// Contoh pemakaian:
  /// ```dart
  /// return RepositoryHelper.execute(() async {
  ///   final data = await remoteDatasource.getData();
  ///   return data;
  /// });
  /// ```
  static Future<Either<Failure, T>> execute<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message ?? 'Unauthorized. Please login again.'));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'Cache error occurred.'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
