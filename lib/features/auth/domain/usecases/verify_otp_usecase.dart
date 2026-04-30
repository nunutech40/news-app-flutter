import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';

class VerifyOTPParams {
  final String verificationId;
  final String smsCode;

  VerifyOTPParams({
    required this.verificationId,
    required this.smsCode,
  });
}

class VerifyOTPUseCase {
  final AuthRepository repository;

  VerifyOTPUseCase(this.repository);

  Future<Either<Failure, String>> call(VerifyOTPParams params) async {
    return await repository.verifyOTP(
      verificationId: params.verificationId,
      smsCode: params.smsCode,
    );
  }
}
