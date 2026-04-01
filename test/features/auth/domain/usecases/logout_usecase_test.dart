import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/usecase/usecase.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/logout_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LogoutUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = LogoutUseCase(mockAuthRepository);
  });

  group('Logout Use Case', () {
    // ----- HAPPY PATH -----
    test('harus mengembalikan tipe Void/Null yang diletakkan dalam bungkus Right saat logout mulus', () async {
      // Arrange
      when(() => mockAuthRepository.logout()).thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, const Right(null));
      verify(() => mockAuthRepository.logout()).called(1);
    });

    // ----- ERROR PATH -----
    test('harus mengembalikan Left(Failure) ke Bloc apabila Repository gagal logout tuntas', () async {
      // Arrange
      when(() => mockAuthRepository.logout())
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Logout Timeout')));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, const Left(ServerFailure(message: 'Logout Timeout')));
      verify(() => mockAuthRepository.logout()).called(1);
    });
  });
}
