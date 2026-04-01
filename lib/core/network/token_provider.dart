/// Abstraction for token access — lives in core, no feature dependency.
/// Implemented by AuthLocalDatasource in the auth feature.
abstract class TokenProvider {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();
}
