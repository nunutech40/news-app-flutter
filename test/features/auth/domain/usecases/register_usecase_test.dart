import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/register_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = RegisterUseCase(mockAuthRepository);
  });

  const tName = 'Nuno';
  const tEmail = 'nuno@mail.com';
  const tPassword = 'password123';
  final tUser = User(id: 1, name: tName, email: tEmail);

  group('Register Use Case', () {
    // ----- HAPPY PATH -----
    test('harus meneruskan parameter lengkap ke repository dan mengembalikan data (Happy Path)', () async {
      // Arrange
      when(() => mockAuthRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => Right(tUser));

      // Act
      final result = await usecase(const RegisterParams(name: tName, email: tEmail, password: tPassword));

      // Assert
      expect(result, Right(tUser));
      verify(() => mockAuthRepository.register(name: tName, email: tEmail, password: tPassword)).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    // ----- ERROR PATH -----
    test('harus return Failure jika repository gagal meregistrasikan user (Error Path)', () async {
      // Arrange
      when(() => mockAuthRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(ServerFailure(message: 'Nama tidak boleh kosong')));

      // Act
      final result = await usecase(const RegisterParams(name: tName, email: tEmail, password: tPassword));

      // Assert
      expect(result, const Left(ServerFailure(message: 'Nama tidak boleh kosong')));
    });
  });
}
