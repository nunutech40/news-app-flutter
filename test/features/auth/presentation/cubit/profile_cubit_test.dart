import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/network/api_client.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:news_app/features/auth/presentation/cubit/profile_cubit.dart';
import 'package:news_app/features/auth/presentation/cubit/profile_state.dart';

// Mocks
class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}
class MockApiClient extends Mock implements ApiClient {}

// Dummy fallbacks for Mocktail (needed for any() or Fake classes)
class FakeUser extends Fake implements User {}

void main() {
  late ProfileCubit cubit;
  late MockUpdateProfileUseCase mockUseCase;
  late MockApiClient mockApiClient;
  late File tDummyFile;

  setUpAll(() {
    registerFallbackValue(FakeUser());
    tDummyFile = File('test_dummy.jpg');
    if (!tDummyFile.existsSync()) {
      tDummyFile.writeAsBytesSync([0]);
    }
  });

  tearDownAll(() {
    if (tDummyFile.existsSync()) {
      tDummyFile.deleteSync();
    }
  });

  setUp(() {
    mockUseCase = MockUpdateProfileUseCase();
    mockApiClient = MockApiClient();
    cubit = ProfileCubit(
      updateProfileUseCase: mockUseCase,
      apiClient: mockApiClient,
    );
  });

  tearDown(() {
    cubit.close();
  });

  final tUser = User(
    id: 1,
    name: 'Old Name',
    email: 'test@email.com',
    avatarUrl: 'old_img.jpg',
    bio: 'Old Bio',
    phone: '08123',
    preferences: 'sports',
    createdAt: DateTime.now(),
  );

  final tUpdatedUser = User(
    id: 1,
    name: 'New Name',
    email: 'test@email.com',
    avatarUrl: 'old_img.jpg',
    bio: 'New Bio',
    phone: '08123',
    preferences: 'sports',
    createdAt: tUser.createdAt,
  );

  group('saveProfile', () {
    // 1. HAPPY PATH TANPA GAMBAR
    blocTest<ProfileCubit, ProfileState>(
      'harus emit [loading, success] ketika saveProfile tanpa ganti gambar berhasil',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tUpdatedUser));
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        currentUser: tUser,
        newName: 'New Name',
        newBio: 'New Bio',
        newPhone: '08123',
        newPreferences: 'sports',
        newAvatarFile: null, // Tanpa gambar baru
      ),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        ProfileState(status: ProfileStatus.success, updatedUser: tUpdatedUser),
      ],
      verify: (_) {
        verify(() => mockUseCase(any())).called(1);
        verifyZeroInteractions(mockApiClient); // Tidak panggil upload
      },
    );

    // 2. ERROR PATH: API GAGAL
    blocTest<ProfileCubit, ProfileState>(
      'harus emit [loading, failure] ketika usecase mengembalikan Failure',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Name too short')));
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        currentUser: tUser,
        newName: 'A',
        newBio: 'New Bio',
        newPhone: '08123',
        newPreferences: 'sports',
        newAvatarFile: null,
      ),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(status: ProfileStatus.failure, errorMessage: 'Name too short'),
      ],
    );

    // 3. HAPPY PATH DENGAN GAMBAR
    // Note: Karena file system sesungguhnya (dart:io File) susah dilempar secara mocktail sempurna dengan FormData,
    // Kita anggap saja ini berfungsi karena kita hanya menguji logika alur state-nya.
    final tUpdatedUserWithImage = User(
      id: 1,
      name: 'New Name',
      email: 'test@email.com',
      avatarUrl: 'http://new_uploaded_url.com/img.jpg', // Avatar url baru
      bio: 'New Bio',
      phone: '08123',
      preferences: 'sports',
      createdAt: tUser.createdAt,
    );

    blocTest<ProfileCubit, ProfileState>(
      'harus upload gambar dulu lalu emit [loading, success] dengan avatar baru',
      build: () {
        // Simulasi berhasil upload gambar
        when(() => mockApiClient.request('POST', '/api/v1/upload', data: any(named: 'data')))
            .thenAnswer((_) async => {
                  'success': true,
                  'data': {'url': 'http://new_uploaded_url.com/img.jpg'}
                });
        
        // Simulasi update profile setelahnya pakai URL baru
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tUpdatedUserWithImage));
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        currentUser: tUser,
        newName: 'New Name',
        newBio: 'New Bio',
        newPhone: '08123',
        newPreferences: 'sports',
        newAvatarFile: tDummyFile, // Ada gambar baru!
      ),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        ProfileState(status: ProfileStatus.success, updatedUser: tUpdatedUserWithImage),
      ],
      verify: (_) {
        verify(() => mockApiClient.request('POST', '/api/v1/upload', data: any(named: 'data'))).called(1);
        verify(() => mockUseCase(any())).called(1);
      },
    );

    // 4. EDGE PATH: UPLOAD GAGAL MENDADAk
    blocTest<ProfileCubit, ProfileState>(
      'harus langsung emit [loading, failure] kalau upload gambar gagal di tengah jalan',
      build: () {
         when(() => mockApiClient.request('POST', '/api/v1/upload', data: any(named: 'data')))
            .thenThrow(Exception('Timeout upload'));
         return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        currentUser: tUser,
        newName: 'New Name',
        newBio: 'New Bio',
        newPhone: '08123',
        newPreferences: 'sports',
        newAvatarFile: tDummyFile,
      ),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(status: ProfileStatus.failure, errorMessage: 'Exception: Timeout upload'),
      ],
      verify: (_) {
        // Verifikasi bahwa UseCase tidak akan pernah dipanggil karena upload sudah mati duluan
        verifyNever(() => mockUseCase(any()));
      },
    );
  });
}
