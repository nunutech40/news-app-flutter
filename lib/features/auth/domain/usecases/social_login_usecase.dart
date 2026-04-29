import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/usecase/usecase.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/services/oauth_service.dart';

class SocialLoginUseCase implements UseCase<AuthTokens, OAuthService> {
  final AuthRepository repository;

  SocialLoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthTokens>> call(OAuthService service) async {
    return await repository.signInWithOAuth(service);
  }
}
