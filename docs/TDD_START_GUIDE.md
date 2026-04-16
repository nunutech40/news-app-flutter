# Panduan Memulai TDD (Fondasi Awal)

Catatan langkah pertama yang harus dieksekusi saat melanjutkan pengerjaan ("coding") untuk proyek `news-app`.

Meskipun target terdekat adalah fitur **Auth**, mengawali pembuatan fitur tersebut menggunakan TDD tidak bisa langsung diketik. TDD pada *layer* fitur membutuhkan fondasi kokoh (alat bantu) dari *layer Core*. Jika langsung memaksa membuat *Test* pada `AuthRepository` sekarang, kita akan terhenti karena belum definisikan konvensi Error (`Failure`) dan antarmuka (*Interface*) pemanggil API (`ApiClient`) untuk dijadikan bahan *mocking*.

Berikut adalah 3 langkah fundamental berurut yang WAJIB diselesaikan terlebih dahulu **sebelum** mulai merangkai *Test Case* pada level fitur:

### Langkah 1: Menginstal Amunisi Persenjataan (`pubspec.yaml`)
Siapkan *package* yang menopang lalu lintas data antar-*layer* dan sarana *testing*.
```yaml
dependencies:
  flutter_bloc: ^9.1.0
  equatable: ^2.0.7
  dartz: ^0.10.1
  dio: ^5.7.0

dev_dependencies:
  mocktail: ^1.0.4
  bloc_test: ^3.3.0
```

### Langkah 2: Membangun Core Error (`core/error/`)
Karena semua fungsi `Repository` akan mengembalikan kondisi `<Either, Failure, T>`, kerangka *error* ini amat genting:
- **`lib/core/error/failures.dart`**: Deklarasikan `Failure` beserta percabangannya (`ServerFailure`, `NetworkFailure`, dll).
- **`lib/core/error/exceptions.dart`**: Deklarasikan *Exception* sistem (`ServerException`) yang nanti akan dikonversi menjadi *Failure*.

### Langkah 3: Merekayasa Core Network (`core/network/api_client.dart`)
Anda belum perlu menulis struktur detail `Dio` atau *Interceptor* kompleks. Cukup rumuskan bentuk antarmuka (Interface / Skeleton) dari `ApiClient`.
```dart
abstract class ApiClient {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });
}
```
**Alasan:** Kerangka kosong ini akan disuntik (*Inject*) ke dalam tes `AuthRepository` dan di-*mocking* balasan JSON-nya menggunakan `mocktail`.

---

**Next Action (Sesudah 3 Langkah di Atas Selesai):**
Barulah kita sah masuk ke folder `features/auth/` dan menyusun berkas uji perdana: `auth_repository_impl_test.dart` untuk memulai siklus **Red - Green - Refactor**.
