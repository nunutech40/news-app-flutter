import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/network/api_client.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:news_app/features/auth/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;
  final ApiClient apiClient; // We need this just for uploading the image

  ProfileCubit({
    required this.updateProfileUseCase,
    required this.apiClient,
  }) : super(const ProfileState());

  /// Helper API for uploading image straight via Dio FormData
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });
      // The back-end creates /public/uploads/xxx.jpg and returns "url": "..."
      final response = await apiClient.request('POST', '/api/v1/upload', data: formData);
      final rawUrl = response['data']['url'] as String?;
      if (rawUrl == null || rawUrl.isEmpty) return null;
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        return rawUrl;
      }
      final base = ApiConstants.baseUrl.endsWith('/')
          ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
          : ApiConstants.baseUrl;
      final path = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
      return '$base$path';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveProfile({
    required User currentUser,
    required String newName,
    required String newBio,
    required String newPhone,
    required String newPreferences,
    File? newAvatarFile,
  }) async {
    emit(state.copyWith(status: ProfileStatus.loading));

    try {
      String finalAvatarUrl = currentUser.avatarUrl;

      // 1. If user selected a new image, upload it first
      if (newAvatarFile != null) {
        final uploadedUrl = await _uploadImage(newAvatarFile);
        if (uploadedUrl != null) {
          finalAvatarUrl = uploadedUrl;
        }
      }

      // 2. Combine the new inputs into a user entity
      final userToUpdate = User(
        id: currentUser.id,
        email: currentUser.email, // email is usually static or handled via separate flow
        name: newName,
        bio: newBio,
        phone: newPhone,
        preferences: newPreferences,
        avatarUrl: finalAvatarUrl,
        createdAt: currentUser.createdAt,
      );

      // 3. Trigger the UseCase
      final result = await updateProfileUseCase(userToUpdate);

      result.fold(
        (failure) => emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: failure.message,
        )),
        (updatedUser) {
          emit(state.copyWith(
            status: ProfileStatus.success,
            updatedUser: updatedUser,
          ));
        },
      );
    } catch (e) {
      // Petakan exception ke pesan yang ramah pengguna.
      // Jangan pernah tampilkan e.toString() mentah ke user karena akan
      // memunculkan teks teknis seperti "DioException [connection error]: ..."
      final String friendlyMessage;
      if (e is NetworkException) {
        friendlyMessage = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      } else if (e is ServerException) {
        friendlyMessage = e.message; // Pesan dari server sudah cukup informatif
      } else if (e is UnauthorizedException) {
        friendlyMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
      } else {
        friendlyMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      }
      emit(state.copyWith(status: ProfileStatus.failure, errorMessage: friendlyMessage));
    }
  }
}
