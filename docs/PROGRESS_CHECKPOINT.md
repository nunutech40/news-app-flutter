# News App - Progress Checkpoint
Created: 2026-04-01

File ini menyimpan riwayat pekerjaan terakhir kita supaya gampang dilanjut di sesi berikutnya.

## 🎯 Pencapaian Terakhir (Selesai)

1. **Setup Arsitektur & Dokumentasi**
   - Clean Architecture pattern siap (Domain, Data, Presentation, Core).
   - Dokumen lengkap **[TRD.md](./TRD.md)** selesai ditulis menyajikan seluruh spesifikasi sistem.
   - Dependency Injection (GetIt) beres sampai layer BLoC.

2. **Core Network Layer (`ApiClient`)**
   - Refactor ke method single-entry `request()`.
   - `_handleDioError` menjadi pusat error mapping ke `ServerException`.
   - **Fix Race Condition:** `AuthInterceptor` sekarang pakai `Completer` buat mencegah spam request token refresh pas kena banyak error `401`.
   - Memutuskan mata rantai dependency layer Fitur memakai interface `TokenProvider`.

3. **Data Layer (Auth)**
   - Perbaikan konversi JSON di `UserModel` (defensive casting buat tipe data ID dan DateTime parsing).
   - `AuthLocalDatasource` disetting **Dual Storage**:
     - *Token* disimpan di `FlutterSecureStorage`.
     - *Cache Profile* disimpan di `SharedPreferences` (bisa offline).
   - `AuthRepositoryImpl` sukses menggabungkan Remote API, Local, dan Error mapping ke `Either<Failure, T>`.

4. **Unit Testing**
   - Setup `mocktail`, `flutter_test`, dan `http_mock_adapter`.
   - Selesai membuat **25 Unit Test** untuk `ApiClient` (mencakup *Happy Path*, *Error Path*, dan *Edge Case* dari Dio).

---

## 🚀 Langkah Selanjutnya (Buat Sesi Berikutnya)

Ketika mulai session baru, tinggal kopas ke saya:
> *"Bro, tolong baca progress_checkpoint.md dan buatin unit test buat layer Datasource."*

**Daftar Tugas yang Belum:**
1. **Unit Test - Data Layer:**
   - Bikin unit test buat `AuthRemoteDatasource` (mock `ApiClient`).
   - Bikin unit test buat `AuthLocalDatasource` (mock `FlutterSecureStorage` & `SharedPreferences`).
   - Bikin unit test buat `AuthRepositoryImpl` (test fallback cache-nya).

2. **Unit Test - Domain & BLoC Layer:**
   - Test `AuthBloc` state management (Validasi flow `initial` -> `loading` -> `authenticated`).

3. **Integrasi UI & Run App:**
   - Matikan/tutup terminal `flutter run`.
   - Build ulang secara full untuk memastikan flow layar `Splash` -> `Login` -> `Dashboard` berjalan dengan interceptor baru.
