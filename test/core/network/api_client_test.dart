import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/network/api_client.dart';
import 'package:news_app/core/bloc/global_alert/global_alert_bloc.dart';
import 'package:news_app/core/bloc/global_alert/global_alert_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/bloc/global_alert/global_alert_state.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK API CLIENT (CORE NETWORK)
// =============================================================================
// 1. FOKUS UTAMA: ApiClient adalah jembatan paling bawah yang langsung bicara
//    dengan library HTTP eksternal (Dio). Tugasnya HANYA mengeksekusi request 
//    dan menerjemahkan HTTP Status Code atau network error bawaan menjadi 
//    Exception yang bersih (ServerException) bagi layer atas.
//
// 2. SKENARIO YANG WAJIB DITEST PADA API CLIENT:
//    a. Konversi HTTP Code: Wajib mengetes berbagai HTTP status (200, 401, 500)
//       karena ini adalah TUGAS EKSKLUSIF dari ApiClient. Layer lain dilarang
//       mengurusi kode HTTP.
//    b. Exception Translation: Pastikan timeout, tidak ada internet, dan error 
//       library Dio dikonversi dengan baik alias error-nya tidak bocor ke luar.
//    c. Data Normalization: Pastikan response sukses dalam berbagai format aneh 
//       (String, List, empty body) agar tetap diubah jadi bentuk JSON/Map baku 
//       (seperti {'data': response}).
// =============================================================================

class MockGlobalAlertBloc extends Mock implements GlobalAlertBloc {}
class FakeShowNetworkFailure extends Fake implements ShowNetworkFailure {}

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late ApiClient apiClient;
  late MockGlobalAlertBloc mockGlobalAlertBloc;

  setUpAll(() {
    registerFallbackValue(FakeShowNetworkFailure());
  });

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.com'));
    dioAdapter = DioAdapter(dio: dio);
    mockGlobalAlertBloc = MockGlobalAlertBloc();
    apiClient = ApiClient.withDio(dio, globalAlertBloc: mockGlobalAlertBloc);
  });

  group('ApiClient.request', () {
    // ==================== Success Cases ====================

    group('successful responses', () {
      test('GET request returns parsed JSON map', () async {
        const path = '/api/v1/auth/me';
        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'name': 'Nunu Nugraha',
            'email': 'nunu@gmail.com',
          },
        };

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, responseData),
        );

        final result = await apiClient.request('GET', path);

        expect(result, equals(responseData));
        expect(result['success'], isTrue);
        expect(result['data']['name'], equals('Nunu Nugraha'));
      });

      test('POST request sends data and returns parsed response', () async {
        const path = '/api/v1/auth/login';
        final requestData = {
          'email': 'nunu@gmail.com',
          'password': '12345678a',
        };
        final responseData = {
          'success': true,
          'data': {
            'access_token': 'eyJabc123',
            'refresh_token': 'eyJdef456',
          },
        };

        dioAdapter.onPost(
          path,
          (server) => server.reply(200, responseData),
          data: requestData,
        );

        final result = await apiClient.request(
          'POST',
          path,
          data: requestData,
        );

        expect(result['success'], isTrue);
        expect(result['data']['access_token'], equals('eyJabc123'));
        expect(result['data']['refresh_token'], equals('eyJdef456'));
      });

      test('handles non-map response by wrapping in data key', () async {
        const path = '/health';

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, 'OK'),
        );

        final result = await apiClient.request('GET', path);

        expect(result, equals({'data': 'OK'}));
      });

      test('PUT request works correctly', () async {
        const path = '/api/v1/user/1';
        final requestData = {'name': 'Updated Name'};
        final responseData = {
          'success': true,
          'data': {'id': 1, 'name': 'Updated Name'},
        };

        dioAdapter.onPut(
          path,
          (server) => server.reply(200, responseData),
          data: requestData,
        );

        final result = await apiClient.request(
          'PUT',
          path,
          data: requestData,
        );

        expect(result['success'], isTrue);
        expect(result['data']['name'], equals('Updated Name'));
      });

      test('DELETE request works correctly', () async {
        const path = '/api/v1/user/1';
        final responseData = {'success': true, 'message': 'Deleted'};

        dioAdapter.onDelete(
          path,
          (server) => server.reply(200, responseData),
        );

        final result = await apiClient.request('DELETE', path);

        expect(result['success'], isTrue);
      });

      test('passes query parameters correctly', () async {
        const path = '/api/v1/news';
        final responseData = {
          'success': true,
          'data': [],
        };

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, responseData),
          queryParameters: {'page': '1', 'limit': '10'},
        );

        final result = await apiClient.request(
          'GET',
          path,
          queryParameters: {'page': '1', 'limit': '10'},
        );

        expect(result['success'], isTrue);
      });
    });

    // ==================== Error Cases ====================

    group('error handling - _handleDioError', () {
      test('401 bad response throws ServerException with API message', () async {
        const path = '/api/v1/auth/login';
        final errorResponse = {
          'success': false,
          'message': 'invalid email or password',
        };

        dioAdapter.onPost(
          path,
          (server) => server.reply(401, errorResponse),
          data: {
            'email': 'wrong@gmail.com',
            'password': 'wrongpassword',
          },
        );

        expect(
          () => apiClient.request(
            'POST',
            path,
            data: {
              'email': 'wrong@gmail.com',
              'password': 'wrongpassword',
            },
          ),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'invalid email or password')
                .having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      });

      test('500 server error throws ServerException with status code', () async {
        const path = '/api/v1/auth/me';

        dioAdapter.onGet(
          path,
          (server) => server.reply(500, 'Internal Server Error'),
        );

        expect(
          () => apiClient.request('GET', path),
          throwsA(
            isA<ServerException>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having((e) => e.message, 'message', contains('Server error')),
          ),
        );
      });

      test('422 validation error extracts message from response', () async {
        const path = '/api/v1/auth/register';
        final errorResponse = {
          'success': false,
          'message': 'email already registered',
        };

        dioAdapter.onPost(
          path,
          (server) => server.reply(422, errorResponse),
          data: {
            'name': 'Test',
            'email': 'existing@gmail.com',
            'password': '12345678a',
          },
        );

        expect(
          () => apiClient.request(
            'POST',
            path,
            data: {
              'name': 'Test',
              'email': 'existing@gmail.com',
              'password': '12345678a',
            },
          ),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'email already registered')
                .having((e) => e.statusCode, 'statusCode', 422),
          ),
        );
      });

      test('bad response with null message falls back to Server error', () async {
        const path = '/api/v1/test';
        final errorResponse = {
          'success': false,
          // no 'message' key
        };

        dioAdapter.onGet(
          path,
          (server) => server.reply(400, errorResponse),
        );

        expect(
          () => apiClient.request('GET', path),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Server error')
                .having((e) => e.statusCode, 'statusCode', 400),
          ),
        );
      });

      test('connection timeout throws ServerException with timeout message', () async {
        const path = '/api/v1/slow';

        dioAdapter.onGet(
          path,
          (server) => server.throws(
            0,
            DioException(
              type: DioExceptionType.connectionTimeout,
              requestOptions: RequestOptions(path: path),
            ),
          ),
        );

        await expectLater(
          () => apiClient.request('GET', path),
          throwsA(
            isA<NetworkException>()
                .having(
                  (e) => e.message,
                  'message',
                  'Connection timed out. Please try again.',
                ),
          ),
        );
        
        verify(() => mockGlobalAlertBloc.add(
              any(that: isA<ShowNetworkFailure>().having((e) => e.isTimeout, 'isTimeout', true)),
            )).called(1);
      });

      test('send timeout throws ServerException with timeout message', () async {
        const path = '/api/v1/upload';

        dioAdapter.onPost(
          path,
          (server) => server.throws(
            0,
            DioException(
              type: DioExceptionType.sendTimeout,
              requestOptions: RequestOptions(path: path),
            ),
          ),
          data: Matchers.any,
        );

        await expectLater(
          () => apiClient.request('POST', path, data: {'file': 'big'}),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              'Connection timed out. Please try again.',
            ),
          ),
        );

        verify(() => mockGlobalAlertBloc.add(
              any(that: isA<ShowNetworkFailure>().having((e) => e.isTimeout, 'isTimeout', true)),
            )).called(1);
      });

      test('receive timeout throws ServerException with timeout message', () async {
        const path = '/api/v1/big-data';

        dioAdapter.onGet(
          path,
          (server) => server.throws(
            0,
            DioException(
              type: DioExceptionType.receiveTimeout,
              requestOptions: RequestOptions(path: path),
            ),
          ),
        );

        await expectLater(
          () => apiClient.request('GET', path),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              'Connection timed out. Please try again.',
            ),
          ),
        );

        verify(() => mockGlobalAlertBloc.add(
              any(that: isA<ShowNetworkFailure>().having((e) => e.isTimeout, 'isTimeout', true)),
            )).called(1);
      });

      test('connection error throws ServerException with no internet message', () async {
        const path = '/api/v1/auth/me';

        dioAdapter.onGet(
          path,
          (server) => server.throws(
            0,
            DioException(
              type: DioExceptionType.connectionError,
              requestOptions: RequestOptions(path: path),
            ),
          ),
        );

        await expectLater(
          () => apiClient.request('GET', path),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              'No internet connection.',
            ),
          ),
        );

        verify(() => mockGlobalAlertBloc.add(
              any(that: isA<ShowNetworkFailure>().having((e) => e.isTimeout, 'isTimeout', false)),
            )).called(1);
      });

      test('cancel DioException falls back to generic message', () async {
        const path = '/api/v1/unknown';

        dioAdapter.onGet(
          path,
          (server) => server.throws(
            0,
            DioException(
              type: DioExceptionType.cancel,
              requestOptions: RequestOptions(path: path),
              message: 'Request cancelled',
            ),
          ),
        );

        expect(
          () => apiClient.request('GET', path),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              anyOf('Request cancelled', 'Something went wrong'),
            ),
          ),
        );
      });

      test('unknown DioException with null message falls back to generic', () async {
        const path = '/api/v1/unknown';

        dioAdapter.onGet(
          path,
          (server) => server.throws(
            0,
            DioException(
              type: DioExceptionType.cancel,
              requestOptions: RequestOptions(path: path),
            ),
          ),
        );

        expect(
          () => apiClient.request('GET', path),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'Something went wrong',
            ),
          ),
        );
      });
    });

    // ==================== Edge Cases ====================

    group('edge cases', () {
      test('empty map response returns empty map', () async {
        const path = '/api/v1/empty';

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, <String, dynamic>{}),
        );

        final result = await apiClient.request('GET', path);

        expect(result, isA<Map<String, dynamic>>());
        expect(result, isEmpty);
      });

      test('null response body wraps as {data: null}', () async {
        const path = '/api/v1/null';

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, null),
        );

        final result = await apiClient.request('GET', path);

        expect(result, equals({'data': null}));
      });

      test('List response wraps in data key', () async {
        const path = '/api/v1/list';
        final listData = [
          {'id': 1, 'title': 'News 1'},
          {'id': 2, 'title': 'News 2'},
        ];

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, listData),
        );

        final result = await apiClient.request('GET', path);

        // List is not Map, so it should be wrapped
        expect(result, equals({'data': listData}));
        expect(result['data'], isList);
        expect((result['data'] as List).length, 2);
      });

      test('integer response wraps in data key', () async {
        const path = '/api/v1/count';

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, 42),
        );

        final result = await apiClient.request('GET', path);

        expect(result, equals({'data': 42}));
      });

      test('boolean response wraps in data key', () async {
        const path = '/api/v1/check';

        dioAdapter.onGet(
          path,
          (server) => server.reply(200, true),
        );

        final result = await apiClient.request('GET', path);

        expect(result, equals({'data': true}));
      });

      test('POST with null data does not crash', () async {
        const path = '/api/v1/ping';
        final responseData = {'success': true};

        dioAdapter.onPost(
          path,
          (server) => server.reply(200, responseData),
          data: null,
        );

        final result = await apiClient.request('POST', path, data: null);

        expect(result['success'], isTrue);
      });

      test('POST with empty map data works', () async {
        const path = '/api/v1/empty-post';
        final responseData = {'success': true};

        dioAdapter.onPost(
          path,
          (server) => server.reply(200, responseData),
          data: <String, dynamic>{},
        );

        final result = await apiClient.request(
          'POST',
          path,
          data: <String, dynamic>{},
        );

        expect(result['success'], isTrue);
      });

      test('error response with nested error object extracts top-level message', () async {
        const path = '/api/v1/nested-error';
        final errorResponse = {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            'email': ['Email is required'],
            'password': ['Password too short'],
          },
        };

        dioAdapter.onPost(
          path,
          (server) => server.reply(422, errorResponse),
          data: Matchers.any,
        );

        expect(
          () => apiClient.request('POST', path, data: {}),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Validation failed')
                .having((e) => e.statusCode, 'statusCode', 422),
          ),
        );
      });

      test('204 No Content with null body does not crash', () async {
        const path = '/api/v1/delete-thing';

        dioAdapter.onDelete(
          path,
          (server) => server.reply(204, null),
        );

        final result = await apiClient.request('DELETE', path);

        expect(result, equals({'data': null}));
      });
    });
  });
}
