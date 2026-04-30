import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordParams {
  final String verificationId;
  final String smsCode;
  final String newPassword;

  ResetPasswordParams({
    required this.verificationId,
    required this.smsCode,
    required this.newPassword,
  });
}

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPasswordWithOTP(
      verificationId: params.verificationId,
      smsCode: params.smsCode,
      newPassword: params.newPassword,
    );
  }
}
