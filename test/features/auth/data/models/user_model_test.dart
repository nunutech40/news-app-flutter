import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/features/auth/data/models/user_model.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK DATA MODELS (SERIALIZATION)
// =============================================================================
// Unit Test untuk Model sangatlah krusial di pengembangan aplikasi Mobile, karena
// di sinilah "Gerbang Pertama" dimana data kotor dari Backend (JSON) menyentuh 
// dunia ketat (Type-Safe) milik Dart/Flutter.
//
// SKENARIO WAJIB:
// 1. Subclass Check (Is-A relationship): 
//    Memastikan Model adalah pewaris sah dari Entity agar bisa disetor ke Repository.
// 2. Happy Path (fromJson): 
//    Memastikan data JSON sempurna diterjemahkan ke Model.
// 3. Edge Path (Defensive Parsing):
//    API sering plin-plan! Kadang format ID berupa Int `id: 12`, 
//    kadang jadi String bertotok `id: "12"`. Model Anda sudah punya fungsi _parseInt,
//    jadi kita harus UJI KETANGGUHANNYA di sini!
// 4. Happy Path (toJson): 
//    Memastikan Model bisa di-pack ulang jadi JSON jika mau dilempar ke Local Storage.
// =============================================================================

void main() {
  final tUserModel = UserModel(
    id: 1,
    name: 'Nunu Nugraha',
    email: 'nunu@mail.com',
    createdAt: DateTime.parse('2026-04-01T12:00:00.000Z'),
  );

  test('harus merupakan subclass murni dari User Entity', () async {
    expect(tUserModel, isA<User>());
  });

  group('fromJson', () {
    // ----- HAPPY PATH -----
    test('harus mereturn struktur Model yang utuh saat format JSON normal (Happy Path)', () async {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'name': 'Nunu Nugraha',
        'email': 'nunu@mail.com',
        'created_at': '2026-04-01T12:00:00.000Z',
      };

      // Act
      final result = UserModel.fromJson(jsonMap);

      // Assert
      expect(result, tUserModel);
    });

    // ----- EDGE PATH (DEFENSIVE PARSING) -----
    test('harus tetap selamat jika tipe data ID dikirim sebagai String bukan Integer (Edge Path - Tipe Kotor)', () async {
      // API diam-diam error format mengirim tipe String "1"
      final Map<String, dynamic> jsonMapStringId = {
        'id': '1', 
        'name': 'Nunu Nugraha',
        'email': 'nunu@mail.com',
        'created_at': '2026-04-01T12:00:00.000Z',
      };

      final result = UserModel.fromJson(jsonMapStringId);

      // Pastikan fungsi _parseInt Anda bekerja menyulap String "1" menjadi Int 1
      expect(result.id, 1);
    });

    test('harus melempar empty/default value jika data JSON terpotong (Missing Fields) (Edge Path)', () async {
      // API mengirim data bolong (Tidak ada nama/email/created_at)
      final Map<String, dynamic> jsonMapMissing = {
        'id': 1,
        // no email or name here
      };

      final result = UserModel.fromJson(jsonMapMissing);

      // Defensive Parsing di UserModel menjaganya agar null-safe!
      expect(result.id, 1);
      expect(result.name, '');
      expect(result.email, '');
      expect(result.createdAt, isNull);
    });
  });

  group('toJson', () {
    // ----- HAPPY PATH -----
    test('harus mengembalikan Map JSON murni yang ekuivalen dengan Model (Happy Path)', () async {
      // Act
      final result = tUserModel.toJson();

      // Assert
      final expectedMap = {
        'id': 1,
        'name': 'Nunu Nugraha',
        'email': 'nunu@mail.com',
        'avatar_url': '',
        'bio': '',
        'phone': '',
        'preferences': '',
        'created_at': '2026-04-01T12:00:00.000Z',
      };
      
      expect(result, expectedMap);
    });
  });
}
