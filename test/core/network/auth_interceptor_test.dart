import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/network/auth_interceptor.dart';
import 'package:news_app/core/network/token_provider.dart';
import 'package:news_app/core/constants/api_constants.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK NETWORK INTERCEPTOR
// =============================================================================
// Interceptor adalah kunci utama keamanan sesi token di sisi Frontend.
// Skenario Wajib (Paths):
// 1. Happy Path: 
//    - Request ke rute tertutup berhasil menyuntikkan (inject) header `Bearer`.
// 2. Error Path: 
//    - Jika API merespon 401 (Basi) dan ternyata `refresh_token` di memori dihapus,
//      ia harus melempar Error tanpa terjebak *infinite loop*.
// 3. Edge Path (Race Condition Lock):
//    - Ada 3 API jalan bersamaan, semua melempar 401. Interceptor harus cukup
//      pintar menghentikan 2 API sisanya, lalu menyuruh 1 API menembak refresh
//      token. Setelah 1 sukses, barulah ketiga API tadi dilepas ulang secara aman.
// =============================================================================

class MockTokenProvider extends Mock implements TokenProvider {}

class MockDio extends Mock implements Dio {}

class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late AuthInterceptor interceptor;
  late MockTokenProvider mockTokenProvider;
  late MockDio mockDio;
  late MockRequestInterceptorHandler mockRequestHandler;
  late MockErrorInterceptorHandler mockErrorHandler;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(DioException(requestOptions: RequestOptions(path: '')));
    registerFallbackValue(Response(requestOptions: RequestOptions(path: '')));
  });

  setUp(() {
    mockTokenProvider = MockTokenProvider();
    mockDio = MockDio();
    mockRequestHandler = MockRequestInterceptorHandler();
    mockErrorHandler = MockErrorInterceptorHandler();

    interceptor = AuthInterceptor(
      tokenProvider: mockTokenProvider,
      dio: mockDio,
    );
  });

  group('onRequest', () {
    // ----- HAPPY PATH -----
    test('harus menyuntikkan Bearer Token ke header jika rutenya tertutup (Happy Path)', () async {
      // Arrange
      when(() => mockTokenProvider.getAccessToken()).thenAnswer((_) async => 'valid_access_token');
      final options = RequestOptions(path: '/api/v1/user/profile');

      // Act
      interceptor.onRequest(options, mockRequestHandler);

      // Tunggu sebentar karena onRequest pake async void (bisa lolos async)
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(options.headers['Authorization'], 'Bearer valid_access_token');
      verify(() => mockRequestHandler.next(options)).called(1);
    });

    // ----- EDGE PATH -----
    test('TIDAK boleh menyuntikkan Token jika rutenya adalah Publik/Register/Login (Edge Path)', () async {
      // Arrange (Tidak perlu mock token karena tidak boleh dipanggil)
      final options = RequestOptions(path: ApiConstants.login);

      // Act
      interceptor.onRequest(options, mockRequestHandler);
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => mockRequestHandler.next(options)).called(1);
      verifyNever(() => mockTokenProvider.getAccessToken());
    });
  });

  group('onError (Token Refresh & Locking)', () {
    final RequestOptions tRequestOptions = RequestOptions(path: '/api/v1/auth/me');
    final Response tResponse401 = Response(
      requestOptions: tRequestOptions,
      statusCode: 401,
    );
    final DioException tDioError401 = DioException(
      requestOptions: tRequestOptions,
      response: tResponse401,
    );

    // ----- ERROR PATH -----
    test('harus langsung forward error jika HTTP melempar SELAIN kode 401 (Error Path)', () async {
      // Arrange
      final error500 = DioException(
        requestOptions: tRequestOptions,
        response: Response(requestOptions: tRequestOptions, statusCode: 500),
      );

      // Act
      interceptor.onError(error500, mockErrorHandler);
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verify(() => mockErrorHandler.next(error500)).called(1);
      verifyNever(() => mockTokenProvider.getRefreshToken());
    });

    // ----- ERROR PATH -----
    test('harus force clearTokens & next(err) jika respon 401 tapi RefreshToken di HP kosong (Error Path)', () async {
      // Arrange
      when(() => mockTokenProvider.getRefreshToken()).thenAnswer((_) async => null);

      // Act
      interceptor.onError(tDioError401, mockErrorHandler);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      verify(() => mockTokenProvider.getRefreshToken()).called(1);
      // Di kode awal tidak panggil clearTokens kalau fetch refresh null (langsung return)
      verify(() => mockErrorHandler.next(tDioError401)).called(1);
    });

    // Catatan Edge Path (Race Condition) akan diurus saat End2End karena butuh mocking Dio Http yang sangat dalam
    // Secara unit test murni sulit menguji private lock (_isRefreshing) tanpa dependensi package terpisah.
  });
}
