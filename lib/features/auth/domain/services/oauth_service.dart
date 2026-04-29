abstract class OAuthService {
  /// The provider name (e.g., 'google', 'apple')
  String get providerName;

  /// Starts the sign-in flow and returns an idToken (or authorization code)
  Future<String> signIn();

  /// Signs out the user from the provider
  Future<void> signOut();
}
