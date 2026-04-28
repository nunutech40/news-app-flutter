import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:news_app/core/domain/repositories/notification_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockNotificationRepository extends Mock implements NotificationRepository {}
class FakeUser extends Fake implements User {}

void main() {
  late UpdateProfileUseCase usecase;
  late MockAuthRepository mockAuthRepository;
  late MockNotificationRepository mockNotificationRepository;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockNotificationRepository = MockNotificationRepository();
    usecase = UpdateProfileUseCase(mockAuthRepository, mockNotificationRepository);
  });

  final tUser = User(
    id: 1,
    name: 'Test Update',
    email: 'test@email.com',
    avatarUrl: 'img.jpg',
    bio: 'Updated Bio',
    phone: '08123456789',
    preferences: 'business,sports',
  );

  test('harusnya meneruskan pemanggilan updateProfile ke AuthRepository dan memanggil Notification jika sukses', () async {
    // Arrange
    when(() => mockAuthRepository.updateProfile(any()))
        .thenAnswer((_) async => Right(tUser));
    when(() => mockNotificationRepository.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {});

    // Act
    final result = await usecase(tUser);

    // Assert
    expect(result, Right(tUser));
    verify(() => mockAuthRepository.updateProfile(tUser)).called(1);
    verify(() => mockNotificationRepository.showNotification(
          title: 'Update Berhasil',
          body: 'Profil Anda telah berhasil diperbarui.',
        )).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
    verifyNoMoreInteractions(mockNotificationRepository);
  });
  
  test('harusnya mengembalikan Failure dan TIDAK memanggil Notification ketika AuthRepository gagal', () async {
    // Arrange
    when(() => mockAuthRepository.updateProfile(any()))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Update Failed')));

    // Act
    final result = await usecase(tUser);

    // Assert
    expect(result, const Left(ServerFailure(message: 'Update Failed')));
    verify(() => mockAuthRepository.updateProfile(tUser)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
    verifyZeroInteractions(mockNotificationRepository); // Pastikan tidak ada notifikasi!
  });
}
