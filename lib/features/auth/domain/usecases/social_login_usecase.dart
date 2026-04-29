import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/usecase/usecase.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/providers/oauth_provider.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';

class SocialLoginUseCase implements UseCase<AuthTokens, OAuthProvider> {
  final AuthRepository repository;

  SocialLoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthTokens>> call(OAuthProvider params) async {
    return await repository.signInWithOAuth(params);
  }
}
