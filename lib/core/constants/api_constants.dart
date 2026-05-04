class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://103.181.143.73:8081';

  // Auth endpoints
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String oauth = '/api/v1/auth/oauth';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String profile = '/api/v1/auth/me';
  static const String logout = '/api/v1/auth/logout';
  static const String forgotPassword = '/api/v1/auth/password/forgot';
  static const String health = '/health';

  // OAuth Clients
  static const String googleWebClientId =
      '578159207410-5cvquhv5kekhr3bb5ueonv2hlqnl36hb.apps.googleusercontent.com';

  // News endpoints
  static const String newsCategories = '/api/v1/news/categories';
  static const String newsFeed = '/api/v1/news';
  static const String newsDetail = '/api/v1/news'; // + /{slug}
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
  static const String profileAvatar = 'profile_avatar';
  static const String profileBio = 'profile_bio';
  static const String profilePhone = 'profile_phone';
  static const String profilePreferences = 'profile_preferences';
}
