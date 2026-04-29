# Eksekusi Plan: Google Sign-In Integration

Dokumen ini memuat rencana eksekusi *end-to-end* untuk mengimplementasikan fitur **Google Sign-In** di proyek RootAppNews (meliputi Backend Go dan Frontend Flutter).

---

## FASE 1: Backend (Go)

### 1. Database Migration
- [x] Buat file migrasi baru: `free-api-news/migrations/011_add_oauth_support.sql`.
- [x] Implementasikan SQL script sesuai rancangan:
  - `ALTER TABLE users ALTER COLUMN password DROP NOT NULL;`
  - Tambahkan kolom `google_id VARCHAR(255) UNIQUE`.
  - Tambahkan kolom `auth_provider VARCHAR(20) DEFAULT 'local'`.
- [ ] Jalankan migrasi di VPS/Database *live*.

### 2. Update Model & Repository
- [ ] Update `models.User` struct (Go) untuk menerima `GoogleID` dan `AuthProvider`.
- [ ] Update `UserRepository`:
  - Tambah fungsi `FindByGoogleID(googleID string) (*models.User, error)`.
  - Modifikasi `CreateUser` agar bisa menerima `Password` yang kosong (NULL) jika `AuthProvider` = `google`.
  - Tambah fungsi `LinkGoogleID(userID int64, googleID string) error`.

### 3. Integrasi SDK Google & Service Logic
- [ ] Tambahkan *dependency*: `go get google.golang.org/api/idtoken`.
- [ ] Update `AuthService` untuk menambahkan metode `OAuthLogin(ctx context.Context, provider string, idToken string)`.
- [ ] Implementasikan logika *Decision Tree* di `AuthService`:
  1. Verifikasi `idToken` ke Google.
  2. Ekstrak `email`, `name`, `sub` (Google ID).
  3. Coba `FindByGoogleID`. Jika ketemu → Login.
  4. Jika tidak, coba `FindByEmail`. Jika ketemu → `LinkGoogleID` → Login.
  5. Jika tidak ketemu sama sekali → `CreateUser` (tanpa password) → Login.

### 4. Controller & Router
- [ ] Buat *handler* baru di `AuthController`: `OAuthLogin(c *gin.Context)`.
- [ ] Daftarkan *endpoint* baru di router: `POST /api/v1/auth/oauth`.
- [ ] Lakukan tes API menggunakan Postman/cURL dengan *dummy* atau *valid idToken*.

---

## FASE 2: Platform Setup (GCP & Flutter)

### 1. Google Cloud Console (GCP)
- [ ] Buat *Project* di Google Cloud Console.
- [ ] Konfigurasi *OAuth consent screen*.
- [ ] Buat *OAuth Client ID* untuk **Web** (digunakan oleh Backend untuk verifikasi).
- [ ] Buat *OAuth Client ID* untuk **Android** (masukkan SHA-1 *debug/release*).
- [ ] Buat *OAuth Client ID* untuk **iOS** (masukkan Bundle ID).

### 2. Flutter Setup
- [ ] Tambahkan package `google_sign_in` ke `pubspec.yaml`.
- [ ] **Android:** Konfigurasi jika dibutuhkan (Cek `strings.xml` / `build.gradle`).
- [ ] **iOS:** Tambahkan `CLIENT_ID` dan `REVERSED_CLIENT_ID` ke `Info.plist`. Daftarkan *URL Types* (URL Schemes) agar aplikasi bisa kembali dari *browser/popup* Google.

---

## FASE 3: Frontend (Flutter)

### 1. Domain Layer
- [ ] Definisikan `abstract class OAuthProvider` (sudah dirancang di `auth.md`).
- [ ] Update `AuthRepository` interface: `Future<Either<Failure, User>> signInWithOAuth(OAuthProvider provider)`.
- [ ] Buat/Update `SocialLoginUseCase` yang memanggil *repository* tersebut.

### 2. Data Layer
- [ ] Buat `GoogleOAuthProvider` yang meng-implement `OAuthProvider`.
  - Class ini akan memanggil `GoogleSignIn().signIn()` dan me-return `idToken`.
- [ ] Update `AuthRemoteDataSource`: Tambahkan pemanggilan HTTP `POST /api/v1/auth/oauth` dengan `idToken`.
- [ ] Implementasi fungsi baru tersebut di `AuthRepositoryImpl`.

### 3. Presentation Layer (BLoC & UI)
- [ ] Tambahkan event baru: `AuthOAuthLoginRequested(OAuthProvider provider)` di `AuthBloc`.
- [ ] Implementasikan *event handler* di `AuthBloc` untuk memanggil `SocialLoginUseCase` dan meng-emit status loading & hasil.
- [ ] Modifikasi UI di `LoginPage`:
  - Hubungkan tombol "Lanjutkan dengan Google" dengan blok BLoC.
  - Pastikan *Loading Indicator* muncul saat proses berlangsung.
  - Tampilkan *Snackbar Error* jika batal/gagal.
