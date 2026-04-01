import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK LOCAL DATASOURCE
// =============================================================================
// 1. FOKUS UTAMA: Local DataSource bertugas menyimpan dan membaca data secara 
//    persisten (offline), misalnya Token di Secure Storage (enskripsi) dan 
//    Data Profil Cache ringan di SharedPreferences.
//
// 2. SKENARIO YANG WAJIB DITEST PADA LOCAL DATASOURCE:
//    a. Write (Save) Data: 
//       Memastikan fungsi write/save memanggil library penyimpanan dengan 
//       "Key Name" (seperti StorageConstants_xxx) dan Value yang tepat.
//    b. Read Data & Return Value: 
//       Menguji respon jika storage ada datanya dan apa jadinya jika kosong (null).
//    c. Partial Cache / Inkonsisten Data: 
//       Bagaimana responsnya jika profil ID tersimpan, tapi email tidak (corrupt cache)? 
//       Harusnya mengembalikan null.
//    d. Clear (Logout) Data: 
//       Memastikan semua key sensitive dan cache terhapus/ter-reset ke null 
//       saat fungsi logout dipanggil.
// =============================================================================

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late AuthLocalDatasourceImpl datasource;
  late MockSecureStorage mockSecureStorage;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    mockSharedPreferences = MockSharedPreferences();
    datasource = AuthLocalDatasourceImpl(
      secureStorage: mockSecureStorage,
      sharedPreferences: mockSharedPreferences,
    );
  });

  group('Tokens (Secure Storage)', () {
    const tAccessToken = 'dummy_access_token';
    const tRefreshToken = 'dummy_refresh_token';

    test('saveTokens harus memangil fungsi write pada secure storage dengan key yang benar', () async {
      // Arrange
      when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      // Act
      await datasource.saveTokens(
        accessToken: tAccessToken,
        refreshToken: tRefreshToken,
      );

      // Assert
      verify(() => mockSecureStorage.write(key: StorageConstants.accessToken, value: tAccessToken)).called(1);
      verify(() => mockSecureStorage.write(key: StorageConstants.refreshToken, value: tRefreshToken)).called(1);
    });

    test('getAccessToken harus mengambil data berdasarkan konstanta key accessor', () async {
      when(() => mockSecureStorage.read(key: StorageConstants.accessToken))
          .thenAnswer((_) async => tAccessToken);

      final result = await datasource.getAccessToken();

      expect(result, tAccessToken);
      verify(() => mockSecureStorage.read(key: StorageConstants.accessToken)).called(1);
    });

    test('hasTokens harus me-return true jika token ada dan tidak kosong', () async {
      when(() => mockSecureStorage.read(key: StorageConstants.accessToken))
          .thenAnswer((_) async => tAccessToken);

      final result = await datasource.hasTokens();

      expect(result, isTrue);
    });

    test('hasTokens harus me-return false jika token null atau string kosong', () async {
      when(() => mockSecureStorage.read(key: StorageConstants.accessToken))
          .thenAnswer((_) async => '');

      final result = await datasource.hasTokens();

      expect(result, isFalse);
    });

    test('clearTokens harus mendelete semua token credential yang tersimpan', () async {
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await datasource.clearTokens();

      verify(() => mockSecureStorage.delete(key: StorageConstants.accessToken)).called(1);
      verify(() => mockSecureStorage.delete(key: StorageConstants.refreshToken)).called(1);
    });
  });

  group('Profile Cache (SharedPreferences)', () {
    const tId = 123;
    const tName = 'Nuno';
    const tEmail = 'nuno@mail.com';

    test('cacheProfile harus mengeset Int dan String menggunakan shared preferences', () async {
      when(() => mockSharedPreferences.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockSharedPreferences.setString(any(), any())).thenAnswer((_) async => true);

      await datasource.cacheProfile(id: tId, name: tName, email: tEmail);

      verify(() => mockSharedPreferences.setInt(StorageConstants.profileId, tId)).called(1);
      verify(() => mockSharedPreferences.setString(StorageConstants.profileName, tName)).called(1);
      verify(() => mockSharedPreferences.setString(StorageConstants.profileEmail, tEmail)).called(1);
    });

    test('getCachedProfile harus me-return map utuh jika semua field Profil ada (Happy Path)', () async {
      when(() => mockSharedPreferences.getInt(StorageConstants.profileId)).thenReturn(tId);
      when(() => mockSharedPreferences.getString(StorageConstants.profileName)).thenReturn(tName);
      when(() => mockSharedPreferences.getString(StorageConstants.profileEmail)).thenReturn(tEmail);

      final result = await datasource.getCachedProfile();

      expect(result, isNotNull);
      expect(result?['id'], tId);
      expect(result?['name'], tName);
      expect(result?['email'], tEmail);
    });

    test('getCachedProfile harus me-return null bila ada satu field saja yang hilang (Edge Path / Corrupt)', () async {
      // Skenario dimana aplikasi crash lalu email gagal tersimpan
      when(() => mockSharedPreferences.getInt(StorageConstants.profileId)).thenReturn(tId);
      when(() => mockSharedPreferences.getString(StorageConstants.profileName)).thenReturn(tName);
      when(() => mockSharedPreferences.getString(StorageConstants.profileEmail)).thenReturn(null);

      final result = await datasource.getCachedProfile();

      expect(result, isNull); // Karena id != null || name != null || email == null (ada yang null)
    });

    test('clearProfile wajib me-remove semua atribut profile yang dicache', () async {
      when(() => mockSharedPreferences.remove(any())).thenAnswer((_) async => true);

      await datasource.clearProfile();

      verify(() => mockSharedPreferences.remove(StorageConstants.profileId)).called(1);
      verify(() => mockSharedPreferences.remove(StorageConstants.profileName)).called(1);
      verify(() => mockSharedPreferences.remove(StorageConstants.profileEmail)).called(1);
    });
  });

  group('clearAll (Full Reset)', () {
    test('clearAll harus membersihkan storage secure sekaligus non-secure', () async {
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
      when(() => mockSharedPreferences.remove(any())).thenAnswer((_) async => true);

      await datasource.clearAll();

      verify(() => mockSecureStorage.delete(key: StorageConstants.accessToken)).called(1);
      verify(() => mockSecureStorage.delete(key: StorageConstants.refreshToken)).called(1);
      verify(() => mockSharedPreferences.remove(StorageConstants.profileId)).called(1);
      verify(() => mockSharedPreferences.remove(StorageConstants.profileName)).called(1);
      verify(() => mockSharedPreferences.remove(StorageConstants.profileEmail)).called(1);
    });
  });
}
