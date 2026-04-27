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
// 2. TIGA SKENARIO PENTING (PATHS) PADA BLOC:
//    a. Happy Path: 
//       Saat `Event` dikirim dan *mock UseCase* me-return `Right()`. Bloc harus
//       memproses dan memancarkan: [State(loading), State(success/authenticated)].
//    b. Error Path: 
//       Saat *mock UseCase* me-return `Left(Failure)`. Bloc akan memancarkan:
//       [State(loading), State(error, message: 'pesan error')].
//    c. Edge Path (Rantai Kejadian Ganda/Inkonsisten):
//       Momen-momen unik yang bisa terjadi di antar-layer. 
//       Misalnya saat App Start (AuthCheck): 
//       Bagaimana jadinya jika Token ada, tapi saat divalidasi ke GetProfile ternyata server mati/gagal? 
//       Apakah Bloc melempar auth(error) atau justru memisahkan user ke status unauthenticated (logout paksa)?
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

  group('AuthCheckRequested (Splash Screen Check)', () {
    // ----- HAPPY PATH -----
    blocTest<AuthBloc, AuthState>(
      'harus me-return state [authenticated, beserta user] jika punya token & tarikan profil sukses (Happy Path)',
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

    // ----- ERROR PATH (Standar Ditolak / Tdk Punya Sesi) -----
    blocTest<AuthBloc, AuthState>(
      'harus me-return state [unauthenticated] jika sejak awal tidak punya token di storage (Error Path Biasa)',
      build: () {
        when(() => mockAuthRepository.isAuthenticated()).thenAnswer((_) async => false);
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    // ----- EDGE PATH -----
    blocTest<AuthBloc, AuthState>(
      'harus mere-route jadi [unauthenticated] bilamana user Punya Token TAPI fetching user profil Gagal/Kadaluarsa (Edge Path Kasus Inkonsisten)',
      build: () {
        // Secara lokal ia punya token (belum terhapus)...
        when(() => mockAuthRepository.isAuthenticated()).thenAnswer((_) async => true);
        // TAPI karena suatu alasan (token basi / API Error), GetProfile gagal dan membuang Failure!
        when(() => mockGetProfileUseCase(any())).thenAnswer((_) async => const Left(UnauthorizedFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        // Ekspektasi: Aplikasi tidak hang, tapi membersihkan sesi dan menyuruh logout ulang.
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  group('AuthLoginRequested', () {
    const tEmail = 'nuno@mail.com';
    const tPassword = 'password123';

    // ----- HAPPY PATH -----
    blocTest<AuthBloc, AuthState>(
      'harus berurutan emit [loading, authenticated] saat Login & GetProfile 100% sukses berantai (Happy Path)',
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

    // ----- ERROR PATH -----
    blocTest<AuthBloc, AuthState>(
      'harus emit [loading, error] saat login itu sendiri langsung ditolak dari server (Error Path)',
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

    // ----- EDGE PATH -----
    blocTest<AuthBloc, AuthState>(
      'harus TETAP emit [loading, authenticated] TAPI tanpa objek User apabila proses Login berhasil namun proses tarik (Fetch) Profil susulan tiba-tiba gagal (Edge Path)',
      build: () {
        // Step 1: Login sukses
        when(() => mockLoginUseCase(any())).thenAnswer((_) async => Right(tTokens));
        // Step 2: Waktu mau GetProfile, internet nge-lag/server down
        when(() => mockGetProfileUseCase(any())).thenAnswer((_) async => const Left(ServerFailure(message: 'Lag')));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        // Sesuai kode Anda, jika getProfile gagal, status tetap authenticated (meski user: null) 
        // karena tokennya toh sudah aman dipegang. Ini case yang jarang ditebak developer amatir!
        const AuthState(status: AuthStatus.authenticated),
      ],
    );
  });

  group('AuthRegisterRequested', () {
    const tName = 'Nuno';
    const tEmail = 'nuno@mail.com';
    const tPassword = 'password123';

    // ----- HAPPY PATH -----
    blocTest<AuthBloc, AuthState>(
      'harus emit [loading, registrationSuccess] jika server merespon sukses membuat akun (Happy Path)',
      build: () {
        when(() => mockRegisterUseCase(any())).thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(name: tName, email: tEmail, password: tPassword)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.registrationSuccess), 
      ],
    );

    // ----- ERROR PATH -----
    blocTest<AuthBloc, AuthState>(
      'harus emit [loading, error] jika server merespon data pendaftaran invalid (Error Path)',
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
    // ----- HAPPY PATH -----
    blocTest<AuthBloc, AuthState>(
      'harus emit [loading, unauthenticated] saat proses hapus sesi logout beres tuntas (Happy Path)',
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
