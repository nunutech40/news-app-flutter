import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/features/auth/domain/services/oauth_service.dart';

class TwitterOAuthService implements OAuthService {
  @override
  String get providerName => 'twitter';

  @override
  Future<String> signIn() async {
    try {
      final twitterProvider = TwitterAuthProvider();
      
      // Memanggil Firebase SDK untuk menampilkan Webview Login Twitter (X)
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(twitterProvider);

      // Mendapatkan Firebase ID Token yang di-generate setelah login berhasil
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID Token for Twitter.');
      }

      return idToken;
    } catch (e) {
      throw Exception('Twitter Sign In failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    // Penanganan logout spesifik provider
  }
}
