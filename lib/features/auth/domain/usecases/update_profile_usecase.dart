import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/usecase/usecase.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileUseCase implements UseCase<User, User> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(User params) async {
    return await repository.updateProfile(params);
  }
}
