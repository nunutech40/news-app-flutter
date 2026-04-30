import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordParams {
  final String firebaseIdToken;
  final String newPassword;

  ResetPasswordParams({
    required this.firebaseIdToken,
    required this.newPassword,
  });
}

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(
      firebaseIdToken: params.firebaseIdToken,
      newPassword: params.newPassword,
    );
  }
}
