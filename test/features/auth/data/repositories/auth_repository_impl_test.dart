import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:news_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:news_app/features/auth/data/models/auth_tokens_model.dart';
import 'package:news_app/features/auth/data/models/user_model.dart';
import 'package:news_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK REPOSITORY (CLEAN ARCHITECTURE)
// =============================================================================
// 1. FOKUS UTAMA: Repository adalah "Sang Konduktor / Orkestrator". 
//    Tugasnya HANYA mengoordinasikan pengambilan data dari Remote dan menyimpannya 
//    di Local, serta MENGKONVERSI raw `Exception` (dari layer Data) menjadi 
//    domain `Failure` (Dartz Either: Left).
//
// 2. SKENARIO YANG WAJIB DITEST PADA REPOSITORY:
//    a. Happy Path (Orkestrasi): 
//       Pastikan ketika Remote berhasil, fungsi save/cache milik Local ikut dipanggil,
//       lalu data dikembalikan dalam bentuk `Right(Entity)`.
//    b. Error Path (Exception to Failure): 
//       Saat Remote melempar `ServerException`, pastikan Repository tidak crash/melempar error,
//       melainkan SECARA AMAN di-*catch* dan dikembalikan sebagai `Left(ServerFailure)`.
//    c. Cache Fallback (Fitur Khusus Offline): 
//       (Khusus seperti getProfile) Saat Remote gagal, pastikan ia mencoba membaca 
//       data cache dari Local. Jika ada, kembalikan `Right(Cache)`.
//    d. Clean Up Safety (Khusus Logout):
//       Pastikan apa pun yang terjadi pada server (entah sukses/error), fungsi untuk 
//       menghapus data penyimpanan lokal (clearAll) TETAP TERPANGGIL.
// =============================================================================

class MockRemoteDatasource extends Mock implements AuthRemoteDatasource {}
class MockLocalDatasource extends Mock implements AuthLocalDatasource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;
  late MockLocalDatasource mockLocal;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    mockLocal = MockLocalDatasource();
    repository = AuthRepositoryImpl(
      remoteDatasource: mockRemote,
      localDatasource: mockLocal,
    );
  });

  group('register', () {
    const tName = 'Nunu';
    const tEmail = 'nunu@mail.com';
    const tPassword = 'pass';
    final tUserModel = UserModel(id: 1, name: tName, email: tEmail, createdAt: DateTime.now());

    // ----- HAPPY PATH -----
    test('harus mengembalikan Right(User) ketika call ke remote sukses', () async {
      // Arrange
      when(() => mockRemote.register(name: any(named: 'name'), email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => tUserModel);

      // Act
      final result = await repository.register(name: tName, email: tEmail, password: tPassword);

      // Assert
      expect(result, Right<Failure, User>(tUserModel));
      verify(() => mockRemote.register(name: tName, email: tEmail, password: tPassword)).called(1);
      // Di fungsi register, kita tidak secara eksplisit menyuruh login otomatis (save cache)
      verifyZeroInteractions(mockLocal); 
    });

    // ----- ERROR PATH -----
    test('harus mengembalikan Left(ServerFailure) ketika remote api melempar ServerException', () async {
      // Arrange
      when(() => mockRemote.register(name: any(named: 'name'), email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const ServerException(message: 'Invalid name'));

      // Act
      final result = await repository.register(name: tName, email: tEmail, password: tPassword);

      // Assert
      expect(result, const Left(ServerFailure(message: 'Invalid name')));
    });

    test('harus mengembalikan Left(NetworkFailure) ketika remote api melempar NetworkException', () async {
      // Arrange
      when(() => mockRemote.register(name: any(named: 'name'), email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const NetworkException(message: 'No Internet'));

      // Act
      final result = await repository.register(name: tName, email: tEmail, password: tPassword);

      // Assert
      expect(result, const Left(NetworkFailure(message: 'No Internet')));
    });

    // ----- EDGE PATH -----
    test('harus mengembalikan Left(ServerFailure) ketika lemparan error tipe tak terduga', () async {
      // Arrange
      when(() => mockRemote.register(name: any(named: 'name'), email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('Unknown system crash'));

      // Act
      final result = await repository.register(name: tName, email: tEmail, password: tPassword);

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });

  group('login', () {
    const tEmail = 'nunu@mail.com';
    const tPassword = 'pass';
    final tTokensModel = AuthTokensModel(accessToken: 'access123', refreshToken: 'refresh456');

    // ----- HAPPY PATH (ORKESTRASI / INTEGRASI) -----
    test('harus memanggil simpan Token ke Lokal jika Login di Remote sukses', () async {
      // Arrange
      when(() => mockRemote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => tTokensModel);
      when(() => mockLocal.saveTokens(accessToken: any(named: 'accessToken'), refreshToken: any(named: 'refreshToken')))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.login(email: tEmail, password: tPassword);

      // Assert
      expect(result, Right<Failure, AuthTokens>(tTokensModel));
      // Pastikan fungsi simpan ke secure storage benar-benar dipanggil
      verify(() => mockLocal.saveTokens(accessToken: 'access123', refreshToken: 'refresh456')).called(1);
    });

    // ----- ERROR PATH -----
    test('harus batal memperbarui Token Lokal dan membalikkan Failure jika Remote gagal', () async {
      // Arrange
      when(() => mockRemote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const ServerException(message: 'Wrong Password'));

      // Act
      final result = await repository.login(email: tEmail, password: tPassword);

      // Assert
      expect(result, const Left(ServerFailure(message: 'Wrong Password')));
      // Fungsi saveTokens HARUS tidak dipanggil (zero interactions) karena login gagal
      verifyZeroInteractions(mockLocal);
    });

    // ----- NETWORK ERROR PATH -----
    test('harus mengembalikan Left(NetworkFailure) jika HP tidak ada koneksi saat Login', () async {
      // Arrange
      when(() => mockRemote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const NetworkException(message: 'Connection timed out'));

      // Act
      final result = await repository.login(email: tEmail, password: tPassword);

      // Assert
      expect(result, const Left(NetworkFailure(message: 'Connection timed out')));
      verifyZeroInteractions(mockLocal);
    });
  });

  group('getProfile', () {
    final tUserModel = UserModel(id: 1, name: 'Nunu', email: 'nunu@mail.com', createdAt: DateTime.now());

    // ----- HAPPY PATH -----
    test('harus mengambil dari Remote lalu di-cache ke Local', () async {
      // Arrange
      when(() => mockRemote.getProfile()).thenAnswer((_) async => tUserModel);
      when(() => mockLocal.cacheProfile(id: any(named: 'id'), name: any(named: 'name'), email: any(named: 'email')))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result, Right<Failure, User>(tUserModel));
      verify(() => mockLocal.cacheProfile(id: 1, name: 'Nunu', email: 'nunu@mail.com')).called(1);
    });

    // ----- FALLBACK PATH (OFFLINE / CACHED) -----
    test('harus membaca Cache Lokal jika Remote melempar NetworkException (Offline/Timeout)', () async {
      // Arrange
      // Remote Error (Misal: No internet connection)
      when(() => mockRemote.getProfile()).thenThrow(const NetworkException(message: 'No Internet'));
      // Tapi untungnya ada cache profile sebelumnya
      when(() => mockLocal.getCachedProfile()).thenAnswer((_) async => {
        'id': 1,
        'name': 'Nunu Cached',
        'email': 'nunu@mail.com'
      });

      // Act
      final result = await repository.getProfile();

      // Assert
      // Harus tetap berhasil menggunakan data lama
      expect(result.fold((l) => false, (r) => r.name == 'Nunu Cached'), isTrue);
      verify(() => mockLocal.getCachedProfile()).called(1);
    });

    // ----- ERROR PATH (Keduanya Gagal) -----
    test('harus return Failure jika Remote gagal DAN Cache Lokal kosong', () async {
      // Arrange
      when(() => mockRemote.getProfile()).thenThrow(const ServerException(message: 'Server Error 500'));
      when(() => mockLocal.getCachedProfile()).thenAnswer((_) async => null);

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result, const Left(ServerFailure(message: 'Server Error 500')));
    });
  });

  group('logout', () {
    // ----- HAPPY PATH -----
    test('harus memanggil remote.logout lalu local.clearAll saat sukses', () async {
      when(() => mockLocal.getRefreshToken()).thenAnswer((_) async => 'token123');
      when(() => mockRemote.logout(refreshToken: any(named: 'refreshToken'))).thenAnswer((_) async {});
      when(() => mockLocal.clearAll()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right(null));
      verify(() => mockRemote.logout(refreshToken: 'token123')).called(1);
      verify(() => mockLocal.clearAll()).called(1);
    });

    // ----- ERROR CLEANUP SAFETY PATH -----
    test('harus TETAP memanggil local.clearAll MESKIPUN remote server menolak membuang (Logout Aman)', () async {
      when(() => mockLocal.getRefreshToken()).thenAnswer((_) async => 'token123');
      // Server error karena timeout saat user menekan tombol logout
      when(() => mockRemote.logout(refreshToken: any(named: 'refreshToken')))
          .thenThrow(const NetworkException(message: 'Timeout offline'));
      when(() => mockLocal.clearAll()).thenAnswer((_) async {});

      final result = await repository.logout();

      // Hasil harus tetap Right (Logout lokal sukses)
      expect(result, const Right(null));
      // Pastikan data sensitif di hp tetap dihapus meski server tidak merespons
      verify(() => mockLocal.clearAll()).called(1);
    });
  group('isAuthenticated', () {
    test('harus return true jika localDatasource memiliki token', () async {
      when(() => mockLocal.hasTokens()).thenAnswer((_) async => true);

      final result = await repository.isAuthenticated();

      expect(result, isTrue);
      verify(() => mockLocal.hasTokens()).called(1);
    });

    test('harus return false jika localDatasource tidak memiliki token', () async {
      when(() => mockLocal.hasTokens()).thenAnswer((_) async => false);

      final result = await repository.isAuthenticated();

      expect(result, isFalse);
      verify(() => mockLocal.hasTokens()).called(1);
    });
  });
}
