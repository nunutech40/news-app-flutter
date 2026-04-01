import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/usecase/usecase.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK BLOC (PRESENTATION LAYER)
// =============================================================================
// 1. FOKUS UTAMA: Menguji TRANSAKSI STATE. Pastikan setiap `Event` yang masuk
//    memproduksi urutan `State` yang benar (contoh: Loading -> Success).
//
// 2. SKENARIO YANG WAJIB DITEST PADA BLOC:
//    a. Posisi Awal (Initial State): Pastikan status bawaannya adalah `initial`.
//    b. Happy Path (Urutan Emisi Sukses): 
//       Saat `Event` dikirim dan *mock UseCase* me-return `Right()`, Bloc harus me-return
//       secara berurutan, misal: [State(loading), State(success)].
//    c. Error Path (Urutan Emisi Gagal): 
//       Saat *mock UseCase* me-return `Left(Failure)`, Bloc harus me-return:
//       [State(loading), State(error, message: 'pesan error')].
//    d. Event Berantai (Chaining):
//       Momen spesial seperti `Login`. Di mana jika `loginUseCase` sukses, ia
//       mengambil data dari `getProfileUseCase`. Pastikan *mock* keduanya aktif.
//
// PERHATIAN: Sangat disarankan memekai plugin `bloc_test` dari Felix Angelov.
// =============================================================================

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    // Daftarkan Fallback jika mocktail bingung membuat nilai default class buatan
    registerFallbackValue(const LoginParams(email: 't', password: 'p'));
    registerFallbackValue(const RegisterParams(name: 'n', email: 'e', password: 'p'));
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockAuthRepository = MockAuthRepository();

    bloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      getProfileUseCase: mockGetProfileUseCase,
      logoutUseCase: mockLogoutUseCase,
      authRepository: mockAuthRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tUser = User(id: 1, name: 'Nuno', email: 'nuno@mail.com');
  final tTokens = AuthTokens(accessToken: 'access_key', refreshToken: 'refresh_key');

  test('initial state harus berstatus initial', () {
    expect(bloc.state, const AuthState(status: AuthStatus.initial));
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'harus me-return state [authenticated, beserta user] jika user punya token dan profil sukses ditarik',
      build: () {
        when(() => mockAuthRepository.isAuthenticated()).thenAnswer((_) async => true);
        when(() => mockGetProfileUseCase(any())).thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'harus me-return state [unauthenticated] jika user tidak punya token sama sekali',
      build: () {
        when(() => mockAuthRepository.isAuthenticated()).thenAnswer((_) async => false);
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  group('AuthLoginRequested', () {
    const tEmail = 'nuno@mail.com';
    const tPassword = 'password123';

    blocTest<AuthBloc, AuthState>(
      'harus berurutan emit [loading, authenticated] saat Login & GetProfile sukses berantai',
      build: () {
        when(() => mockLoginUseCase(any())).thenAnswer((_) async => Right(tTokens));
        when(() => mockGetProfileUseCase(any())).thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'harus emit [loading, error] saat login gagal dari server',
      build: () {
        when(() => mockLoginUseCase(any())).thenAnswer((_) async => const Left(ServerFailure(message: 'Wrong Password')));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.error, errorMessage: 'Wrong Password'),
      ],
    );
  });

  group('AuthRegisterRequested', () {
    const tName = 'Nuno';
    const tEmail = 'nuno@mail.com';
    const tPassword = 'password123';

    blocTest<AuthBloc, AuthState>(
      'harus emit [loading, registrationSuccess] jika server merespon sukses',
      build: () {
        when(() => mockRegisterUseCase(any())).thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(name: tName, email: tEmail, password: tPassword)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.registrationSuccess), // Cek kode AuthBloc, user tidak disimpan di state register
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'harus emit [loading, error] jika server merespon data invalid',
      build: () {
        when(() => mockRegisterUseCase(any())).thenAnswer((_) async => const Left(ServerFailure(message: 'Email Already In Use')));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(name: tName, email: tEmail, password: tPassword)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.error, errorMessage: 'Email Already In Use'),
      ],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'harus emit [loading, unauthenticated] saat proses hapus sesi tuntas',
      build: () {
        when(() => mockLogoutUseCase(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });
}
