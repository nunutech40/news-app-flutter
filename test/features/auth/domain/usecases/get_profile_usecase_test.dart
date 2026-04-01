import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  test('harus membaca fungsi getProfile pada repository tanpa parameter', () async {
    // Arrange
    when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => Right(tUser));

    // Act
    final result = await usecase(NoParams());

    // Assert
    expect(result, Right(tUser));
    verify(() => mockAuthRepository.getProfile()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
