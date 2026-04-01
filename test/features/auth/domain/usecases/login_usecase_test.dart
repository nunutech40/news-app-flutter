import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/login_usecase.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK USE CASE (DOMAIN LAYER)
// =============================================================================
// Walaupun sebagian besar UseCase saat ini hanya menjadi "jembatan penerus"
// (forwarding) ke Repository. Kita TETAP HARUS menguji konsistensi balasan
// (return integrity) di setiap kemungkinannya.
//
// 1. Happy Path: Pastikan ia menerima nilai `Right(Entity)` dari Repository 
//    lalu meneruskannya utuh ke layer di atasnya (Bloc).
// 2. Error Path: Pastikan jika Repository membuang `Left(Failure)`, UseCase
//    meneruskan nilai tersebut tanpa ada yang bocor menjadi *crash* / terubah.
// =============================================================================

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = LoginUseCase(mockAuthRepository);
  });

  const tEmail = 'test@gmail.com';
  const tPassword = 'password123';
  final tTokens = AuthTokens(accessToken: 'access123', refreshToken: 'refresh456');

  group('Login Use Case', () {
    // ----- HAPPY PATH -----
    test('harus meneruskan call login ke repository dan mengembalikan Right(AuthTokens)', () async {
      // Arrange
      when(() => mockAuthRepository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => Right(tTokens));

      // Act
      final result = await usecase(const LoginParams(email: tEmail, password: tPassword));

      // Assert
      expect(result, Right(tTokens));
      verify(() => mockAuthRepository.login(email: tEmail, password: tPassword)).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    // ----- ERROR PATH -----
    test('harus meneruskan call login ke repository dan melempar Left(Failure) ke atas', () async {
      // Arrange
      when(() => mockAuthRepository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Email belum terdaftar')));

      // Act
      final result = await usecase(const LoginParams(email: tEmail, password: tPassword));

      // Assert
      expect(result, const Left(ServerFailure(message: 'Email belum terdaftar')));
      verify(() => mockAuthRepository.login(email: tEmail, password: tPassword)).called(1);
    });
  });
}
