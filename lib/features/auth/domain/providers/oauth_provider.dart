abstract class OAuthProvider {
  /// The provider name (e.g., 'google', 'apple')
  String get providerName;

  /// Initiate the sign in process and return the ID Token
  Future<String> signIn();

  /// Sign out from the provider
  Future<void> signOut();
}
