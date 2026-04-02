import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/core/network/token_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDatasource implements TokenProvider {
  // Token management (from TokenProvider)
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  @override
  Future<String?> getAccessToken();
  @override
  Future<String?> getRefreshToken();
  @override
  Future<void> clearTokens();

  // Session check
  Future<bool> hasTokens();

  // Profile cache
  Future<void> cacheProfile({
    required int id,
    required String name,
    required String email,
    String avatarUrl = '',
    String bio = '',
    String phone = '',
    String preferences = '',
  });
  Future<Map<String, dynamic>?> getCachedProfile();
  Future<void> clearProfile();

  // Clear everything (logout)
  Future<void> clearAll();
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  final FlutterSecureStorage secureStorage; // Sensitive: tokens
  final SharedPreferences sharedPreferences; // Non-sensitive: profile cache

  AuthLocalDatasourceImpl({
    required this.secureStorage,
    required this.sharedPreferences,
  });

  // ==================== Tokens (Secure) ====================

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      secureStorage.write(
        key: StorageConstants.accessToken,
        value: accessToken,
      ),
      secureStorage.write(
        key: StorageConstants.refreshToken,
        value: refreshToken,
      ),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: StorageConstants.accessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: StorageConstants.refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      secureStorage.delete(key: StorageConstants.accessToken),
      secureStorage.delete(key: StorageConstants.refreshToken),
    ]);
  }

  @override
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ==================== Profile Cache (SharedPrefs) ====================

  @override
  Future<void> cacheProfile({
    required int id,
    required String name,
    required String email,
    String avatarUrl = '',
    String bio = '',
    String phone = '',
    String preferences = '',
  }) async {
    await Future.wait([
      sharedPreferences.setInt(StorageConstants.profileId, id),
      sharedPreferences.setString(StorageConstants.profileName, name),
      sharedPreferences.setString(StorageConstants.profileEmail, email),
      sharedPreferences.setString(StorageConstants.profileAvatar, avatarUrl),
      sharedPreferences.setString(StorageConstants.profileBio, bio),
      sharedPreferences.setString(StorageConstants.profilePhone, phone),
      sharedPreferences.setString(StorageConstants.profilePreferences, preferences),
    ]);
  }

  @override
  Future<Map<String, dynamic>?> getCachedProfile() async {
    final id = sharedPreferences.getInt(StorageConstants.profileId);
    final name = sharedPreferences.getString(StorageConstants.profileName);
    final email = sharedPreferences.getString(StorageConstants.profileEmail);
    final avatarUrl = sharedPreferences.getString(StorageConstants.profileAvatar) ?? '';
    final bio = sharedPreferences.getString(StorageConstants.profileBio) ?? '';
    final phone = sharedPreferences.getString(StorageConstants.profilePhone) ?? '';
    final preferences = sharedPreferences.getString(StorageConstants.profilePreferences) ?? '';

    if (id == null || name == null || email == null) return null;

    return {
      'id': id, 
      'name': name, 
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'phone': phone,
      'preferences': preferences,
    };
  }

  @override
  Future<void> clearProfile() async {
    await Future.wait([
      sharedPreferences.remove(StorageConstants.profileId),
      sharedPreferences.remove(StorageConstants.profileName),
      sharedPreferences.remove(StorageConstants.profileEmail),
      sharedPreferences.remove(StorageConstants.profileAvatar),
      sharedPreferences.remove(StorageConstants.profileBio),
      sharedPreferences.remove(StorageConstants.profilePhone),
      sharedPreferences.remove(StorageConstants.profilePreferences),
    ]);
  }

  // ==================== Clear All ====================

  @override
  Future<void> clearAll() async {
    await Future.wait([
      clearTokens(),
      clearProfile(),
    ]);
  }
}
