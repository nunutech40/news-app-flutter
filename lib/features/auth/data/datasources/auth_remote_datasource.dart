import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/network/api_client.dart';
import 'package:news_app/features/auth/data/models/auth_tokens_model.dart';
import 'package:news_app/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthTokensModel> login({
    required String email,
    required String password,
  });

  Future<AuthTokensModel> signInWithOAuth({
    required String provider,
    required String idToken,
  });

  Future<UserModel> getProfile();

  Future<UserModel> updateProfile(UserModel user);

  Future<void> logout({required String refreshToken});
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient apiClient;

  AuthRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.request('POST', ApiConstants.register,
      data: {'name': name, 'email': email, 'password': password},
    );

    if (response['success'] == true) {
      return UserModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ServerException(
      message: response['message'] as String? ?? 'Registration failed',
    );
  }

  @override
  Future<AuthTokensModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.request('POST', ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    if (response['success'] == true) {
      return AuthTokensModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ServerException(
      message: response['message'] as String? ?? 'Login failed',
    );
  }

  @override
  Future<AuthTokensModel> signInWithOAuth({
    required String provider,
    required String idToken,
  }) async {
    final response = await apiClient.request('POST', ApiConstants.oauth,
      data: {'provider': provider, 'id_token': idToken},
    );

    if (response['success'] == true) {
      return AuthTokensModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ServerException(
      message: response['message'] as String? ?? 'OAuth Login failed',
    );
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.request('GET', ApiConstants.profile);

    if (response['success'] == true) {
      return UserModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ServerException(
      message: response['message'] as String? ?? 'Failed to get profile',
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await apiClient.request('POST', ApiConstants.logout,
      data: {'refresh_token': refreshToken},
    );
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final response = await apiClient.request(
      'PUT', 
      ApiConstants.profile,
      data: {
        'name': user.name,
        'avatar_url': user.avatarUrl,
        'bio': user.bio,
        'phone': user.phone,
        'preferences': user.preferences,
      },
    );

    if (response['success'] == true) {
      return UserModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ServerException(
      message: response['message'] as String? ?? 'Failed to update profile',
    );
  }
}
