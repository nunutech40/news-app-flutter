import 'package:google_sign_in/google_sign_in.dart';
import 'package:news_app/features/auth/domain/services/oauth_service.dart';

class GoogleOAuthService implements OAuthService {
  final String? serverClientId;
  bool _isInitialized = false;

  GoogleOAuthService({this.serverClientId});

  @override
  String get providerName => 'google';

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
      _isInitialized = true;
    }
  }

  @override
  Future<String> signIn() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate();
      
      if (account == null) {
        throw Exception('User canceled Google Sign In');
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
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
