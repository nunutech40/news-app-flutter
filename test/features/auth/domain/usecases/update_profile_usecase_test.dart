import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/update_profile_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class FakeUser extends Fake implements User {}

void main() {
  late UpdateProfileUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = UpdateProfileUseCase(mockAuthRepository);
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

  test('harusnya meneruskan pemanggilan updateProfile ke AuthRepository dan mengembalikan UseCase result', () async {
    // Arrange
    when(() => mockAuthRepository.updateProfile(any()))
        .thenAnswer((_) async => Right(tUser));

    // Act
    final result = await usecase(tUser);

    // Assert
    expect(result, Right(tUser));
    verify(() => mockAuthRepository.updateProfile(tUser)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
  
  test('harusnya mengembalikan Failure ketika AuthRepository gagal', () async {
    // Arrange
    when(() => mockAuthRepository.updateProfile(any()))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Update Failed')));

    // Act
    final result = await usecase(tUser);

    // Assert
    expect(result, const Left(ServerFailure(message: 'Update Failed')));
    verify(() => mockAuthRepository.updateProfile(tUser)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
