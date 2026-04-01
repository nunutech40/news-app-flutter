import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/usecase/usecase.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/get_profile_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetProfileUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = GetProfileUseCase(mockAuthRepository);
  });

  final tUser = User(id: 1, name: 'Nuno', email: 'nuno@mail.com');

  group('Get Profile Use Case', () {
    // ----- HAPPY PATH -----
    test('harus me-return data User (Right) ketika Repository membalikkan nilai utuh (Happy Path)', () async {
      // Arrange
      when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => Right(tUser));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, Right(tUser));
      verify(() => mockAuthRepository.getProfile()).called(1);
    });

    // ----- ERROR PATH -----
    test('harus me-return Failure (Left) ketika Repository membalikkan Server/Cache Failure (Error Path)', () async {
      // Arrange
      when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => const Left(CacheFailure(message: 'Data Profile Hilang')));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, const Left(CacheFailure(message: 'Data Profile Hilang')));
    });
  });
}
