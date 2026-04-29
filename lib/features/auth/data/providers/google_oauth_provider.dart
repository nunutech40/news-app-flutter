import 'package:google_sign_in/google_sign_in.dart';
import 'package:news_app/features/auth/domain/providers/oauth_provider.dart';

class GoogleOAuthProvider implements OAuthProvider {
  final GoogleSignIn _googleSignIn;

  GoogleOAuthProvider({String? serverClientId}) 
    : _googleSignIn = GoogleSignIn(serverClientId: serverClientId);

  @override
  String get providerName => 'google';

  @override
  Future<String> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        throw Exception('Sign in was canceled by the user.');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      
      final String? idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Failed to get idToken from Google.');
      }

      return idToken;
    } catch (e) {
      throw Exception('Google Sign In failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
