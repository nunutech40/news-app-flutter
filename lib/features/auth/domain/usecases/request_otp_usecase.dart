import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';

class RequestOTPUseCase {
  final AuthRepository repository;

  RequestOTPUseCase(this.repository);

  Future<Either<Failure, String>> call(String phoneNumber) async {
    return await repository.requestOTP(phoneNumber: phoneNumber);
  }
}
