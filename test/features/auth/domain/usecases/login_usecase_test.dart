import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/login_usecase.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK USE CASE (DOMAIN LAYER)
// =============================================================================
// 1. FOKUS UTAMA: Use Case adalah tempat "Bisnis Logic" murni yang tidak 
//    memiliki dependency ke Framework (Flutter) atau library eksternal.
//    Tugas Use Case utamanya 90% hanyalah MENERUSKAN (Forwarding) *request* 
//    dari Bloc ke Repository.
//
// 2. SKENARIO YANG WAJIB DITEST PADA USE CASE:
//    a. Single Responsibility: 
//       Pastikan Use Case memanggil method/fungsi Repository YANG TEPAT dengan 
//       parameter yang sama persis seperti yang diminta.
//    b. Return Integrity: 
//       Pastikan apa pun yang dikembalikan (Right/Left) oleh Repository 
//       ditebeng/dicopy keluar dari UseCase tanpa dimodifikasi diam-diam.
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

  test('harus meneruskan call login ke repository dan mengembalikan AuthTokens', () async {
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
}
