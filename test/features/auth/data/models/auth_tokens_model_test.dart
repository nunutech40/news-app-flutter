import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/features/auth/data/models/auth_tokens_model.dart';
import 'package:news_app/features/auth/domain/entities/auth_tokens.dart';

void main() {
  const tAuthTokensModel = AuthTokensModel(
    accessToken: 'mock_access_token',
    refreshToken: 'mock_refresh_token',
  );

  test('harus merupakan subclass murni dari AuthTokens Entity', () async {
    expect(tAuthTokensModel, isA<AuthTokens>());
  });

  group('fromJson', () {
    // ----- HAPPY PATH -----
    test('harus sukses mereturn model saat disuplai JSON bersih dan lengkap (Happy Path)', () async {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'access_token': 'mock_access_token',
        'refresh_token': 'mock_refresh_token',
      };

      // Act
      final result = AuthTokensModel.fromJson(jsonMap);

      // Assert
      expect(result, tAuthTokensModel);
    });

    // ----- ERROR PATH -----
    test('harus melempar TypeError (Crash Tertangkap) jika API tidak mengirimkan key wajib (Error Path)', () async {
      // Arrange
      final Map<String, dynamic> badJsonMap = {
        // Hilang akses tokennya
        'refresh_token': 'mock_refresh_token',
      };

      // Act
      final call = AuthTokensModel.fromJson;

      // Assert (Akan dilempar crash TypeError di Dart karena kita memaksakan 'as String' pada null)
      expect(() => call(badJsonMap), throwsA(isA<TypeError>()));
    });
  });
}
