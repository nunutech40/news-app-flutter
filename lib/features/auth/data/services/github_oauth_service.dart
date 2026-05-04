import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/features/auth/domain/services/oauth_service.dart';

class GithubOAuthService implements OAuthService {
  @override
  String get providerName => 'github';

  @override
  Future<String> signIn() async {
    try {
      final githubProvider = GithubAuthProvider();
      
      // Memanggil Firebase SDK untuk menampilkan Webview Login GitHub
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(githubProvider);

      // Mendapatkan Firebase ID Token yang di-generate setelah login berhasil
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID Token for GitHub.');
      }

      return idToken;
    } catch (e) {
      throw Exception('GitHub Sign In failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    // Penanganan logout spesifik provider (biasanya di-handle global via FirebaseAuth.instance.signOut())
  }
}
