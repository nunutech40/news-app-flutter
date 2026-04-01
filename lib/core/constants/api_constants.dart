class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://103.181.143.73:8081';

  // Auth endpoints
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String profile = '/api/v1/auth/me';
  static const String logout = '/api/v1/auth/logout';
  static const String health = '/health';
}

class StorageConstants {
  StorageConstants._();

  // Secure Storage (sensitive)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // SharedPreferences (non-sensitive cache)
  static const String profileId = 'profile_id';
  static const String profileName = 'profile_name';
  static const String profileEmail = 'profile_email';
}
