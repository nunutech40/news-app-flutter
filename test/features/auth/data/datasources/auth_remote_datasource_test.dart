import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/network/api_client.dart';
import 'package:news_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:news_app/features/auth/data/models/auth_tokens_model.dart';
import 'package:news_app/features/auth/data/models/user_model.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK REMOTE DATASOURCE
// =============================================================================
// 1. FOKUS UTAMA: Tugas DataSource hanyalah memanggil Core Network (ApiClient)
//    lalu melakukan PARSING data mentah (JSON) menjadi objek Model aplikasi.
//    Test di file ini tidak boleh peduli soal kode HTTP (404, 500), karena
//    hal tersebut sudah dites dan di-handle seratus persen oleh ApiClient.
//
// 2. TIGA SKENARIO PENTING (PATHS):
//    a. Happy Path: 
//         - Seting Mock ApiClient membalas dengan Map JSON valid + status success: true.
//         - Ekspektasi: Metode selesai tanpa error dan kembalian datanya adalah 
//           model yang benar (misal: UserModel).
//    b. Error Path (Exception Forwarding):
//         - Seting Mock ApiClient seolah-olah melempar `ServerException`.
//         - Ekspektasi: Exception tersebut "naik" dengan mulus (re-throw) 
//           melalui DataSource tanpa tertelan.
//    c. Edge Path (Aneh/Unexpected Response):
//         - Seting Mock ApiClient membalas dengan status JSON success: false.
//         - Ekspektasi: Kode kita melempar ServerException dengan pesan error dari JSON.
//         - *Atau*: JSON kehilangan key mandatory (Parsing Error -> TypeError).
// =============================================================================

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AuthRemoteDatasourceImpl datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = AuthRemoteDatasourceImpl(apiClient: mockApiClient);
  });

  group('register', () {
    const tName = 'Nunu';
    const tEmail = 'nunu@example.com';
    const tPassword = 'password123';
    
    final tRequestData = {
      'name': tName,
      'email': tEmail,
      'password': tPassword,
    };

    final tJsonResponseSuccess = {
      'success': true,
      'data': {
        'id': '123',
        'name': tName,
        'email': tEmail,
        'created_at': '2026-04-01T00:00:00Z',
      }
    };

    final tJsonResponseFailed = {
      'success': false,
      'message': 'Email already in use'
    };

    // ----- HAPPY PATH -----
    test('harus mengembalikan UserModel ketika response berhasil (success: true)', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any(), data: any(named: 'data')))
          .thenAnswer((_) async => tJsonResponseSuccess);

      // Act
      final result = await datasource.register(
        name: tName,
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result, isA<UserModel>());
      expect(result.name, tName);
      
      // Verifikasi bahwa ApiClient benar-benar dipanggil 1 kali di path yang benar
      verify(() => mockApiClient.request('POST', ApiConstants.register, data: tRequestData)).called(1);
    });

    // ----- EDGE PATH (Logic Failed) -----
    test('harus melempar ServerException dari API ketika success: false', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any(), data: any(named: 'data')))
          .thenAnswer((_) async => tJsonResponseFailed);

      // Act
      final call = datasource.register(
        name: tName,
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(() => call, throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Email already in use')));
    });

    // ----- ERROR PATH (Exception dari core/network) -----
    test('harus melempar kembali ServerException jika terjadi error di ApiClient', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any(), data: any(named: 'data')))
          .thenThrow(const ServerException(message: 'Connection Timeout'));

      // Act
      final call = datasource.register;

      // Assert
      expect(
        () => call(name: tName, email: tEmail, password: tPassword),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('login', () {
    const tEmail = 'nunu@example.com';
    const tPassword = 'password123';
    
    final tJsonResponseSuccess = {
      'success': true,
      'data': {
        'access_token': 'dummy_access_token',
        'refresh_token': 'dummy_refresh_token',
      }
    };

    // ----- HAPPY PATH -----
    test('harus mengembalikan AuthTokensModel ketika proses login sukses', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any(), data: any(named: 'data')))
          .thenAnswer((_) async => tJsonResponseSuccess);

      // Act
      final result = await datasource.login(email: tEmail, password: tPassword);

      // Assert
      expect(result, isA<AuthTokensModel>());
      expect(result.accessToken, 'dummy_access_token');
      expect(result.refreshToken, 'dummy_refresh_token');
    });

    // ----- EDGE PATH (Tipe data parsing salah - Null Exception) -----
    test('harus melempar error saat JSON response t.idak memiliki key data yang benar (Parsing Mismatch)', () async {
      // Arrange
      // "data" dikembalikan sebagai null, dan "success" true. Ini mensimulasikan
      // ketika API Backend ada perubahan dadakan dan membuat aplikasi pecah (type mismatch)
      when(() => mockApiClient.request(any(), any(), data: any(named: 'data')))
          .thenAnswer((_) async => {'success': true, 'data': null});

      // Act
      final call = datasource.login(email: tEmail, password: tPassword);

      // Assert (Akan melempar tipe data error karena UserModel.fromJson butuh Map non-null)
      expect(() => call, throwsA(isA<TypeError>())); 
    });
  });

  group('getProfile', () {
    final tJsonResponseSuccess = {
      'success': true,
      'data': {
        'id': '999',
        'name': 'Ganteng',
        'email': 'ganteng@mail.com',
        'created_at': '2026-04-01T00:00:00Z',
      }
    };

    // ----- HAPPY PATH -----
    test('harus mengembalikan profil pengguna (UserModel) saat token valid dan sukses', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any()))
          .thenAnswer((_) async => tJsonResponseSuccess);

      // Act
      final result = await datasource.getProfile();

      // Assert
      expect(result, isA<UserModel>());
      expect(result.name, 'Ganteng');
      verify(() => mockApiClient.request('GET', ApiConstants.profile)).called(1);
    });

    // ----- EDGE PATH (Token invalid / User not found) -----
    test('harus melempar ServerException saat status JSON mengindikasikan gagal mendapatkan profil', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any()))
          .thenAnswer((_) async => {
            'success': false,
            'message': 'Token kedaluwarsa'
          });

      // Act
      final call = datasource.getProfile();

      // Assert
      expect(() => call, throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Token kedaluwarsa')));
    });
  });

  group('logout', () {
    const tRefreshToken = 'my_refresh_token_123';

    // ----- HAPPY PATH -----
    test('harus tidak mengembalikan error saat logout berhasil di server', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any(), data: any(named: 'data')))
          .thenAnswer((_) async => {'success': true, 'message': 'Logged out'});

      // Act
      final call = datasource.logout(refreshToken: tRefreshToken);

      // Assert
      // Pastikan fungsi berjalan lancar tanpa ada error (completes)
      expect(call, completes);
      
      // Pastikan Request ke endpoint tepat dengan data yang dikirim 'refresh_token'
      verify(() => mockApiClient.request(
        'POST', 
        ApiConstants.logout, 
        data: {'refresh_token': tRefreshToken}
      )).called(1);
    });

    // ----- ERROR PATH -----
    test('harus melempar ServerException saat jaringan mati atau server menolak', () async {
      // Arrange
      when(() => mockApiClient.request(any(), any(), data: any(named: 'data')))
          .thenThrow(const ServerException(message: 'Offline'));

      // Act
      final call = datasource.logout(refreshToken: tRefreshToken);

      // Assert
      expect(() => call, throwsA(isA<ServerException>()));
    });
  });
}
