import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/usecase/usecase.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';

import 'package:news_app/core/domain/repositories/notification_repository.dart';

class UpdateProfileUseCase implements UseCase<User, User> {
  final AuthRepository repository;
  final NotificationRepository notificationRepository;

  UpdateProfileUseCase(this.repository, this.notificationRepository);

  @override
  Future<Either<Failure, User>> call(User params) async {
    final result = await repository.updateProfile(params);
    
    // Jika update berhasil, UseCase bertanggung jawab memicu notifikasi!
    result.fold(
      (failure) => null,
      (user) {
        notificationRepository.showNotification(
          title: 'Update Berhasil',
          body: 'Profil Anda telah berhasil diperbarui.',
        );
      },
    );

    return result;
  }
}
