import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/utils/exception_mapper.dart';

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
      return Left(ServerFailure(message: ExceptionMapper.toMessage(e), statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: ExceptionMapper.toMessage(e)));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: ExceptionMapper.toMessage(e)));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: ExceptionMapper.toMessage(e)));
    } on ParsingException catch (e) {
      return Left(ServerFailure(message: ExceptionMapper.toMessage(e)));
    } catch (e) {
      return Left(ServerFailure(message: ExceptionMapper.toMessage(e)));
    }
  }
}
