# Eksekusi Plan: GitHub Sign-In Integration

Dokumen ini memuat rencana eksekusi *end-to-end* untuk mengimplementasikan fitur **GitHub Sign-In** di proyek RootAppNews (Backend Go dan Frontend Flutter).

---

## PERBEDAAN KRUSIAL DENGAN GOOGLE SIGN-IN
Meskipun alur bisnisnya sama, secara arsitektur teknis ada perbedaan di validasi token:
- **Google** menggunakan **OpenID Connect (OIDC)**: Me-return `idToken` (berupa JWT) yang bisa didecode & diverifikasi secara lokal/mudah di backend.
- **GitHub** murni menggunakan **OAuth 2.0**: Me-return `accessToken`. Backend Go tidak bisa mendecode token ini, melainkan harus mengirim HTTP Request `GET https://api.github.com/user` dengan header `Authorization: Bearer <accessToken>` untuk menarik data user (GitHub ID, Nama, Email).

---

## FASE 1: Backend (Go)

### 1. Database Migration
- [ ] Buat file migrasi baru: `free-api-news/migrations/012_add_github_oauth.sql`.
- [ ] Tambahkan kolom `github_id VARCHAR(255) UNIQUE`.

### 2. Update Model & Repository
- [ ] Update `models.User` struct (Go) untuk menerima `GithubID`.
- [ ] Update `UserRepository`:
  - Tambah fungsi `FindByGithubID(githubID string) (*models.User, error)`.
  - Tambah fungsi `LinkGithubID(userID int64, githubID string) error`.

### 3. Integrasi API GitHub & Service Logic
- [ ] Update `AuthService.OAuthLogin` untuk membedakan provider `google` dan `github`.
- [ ] Jika `provider == "github"`:
  - Token yang diterima dari client dianggap sebagai `accessToken`.
  - Lakukan pemanggilan HTTP: `GET https://api.github.com/user`
  - *Extract* `login` (atau `id` sebagai Github ID), `name`, dan `email` (jika email tidak public, mungkin butuh call ke `https://api.github.com/user/emails`).
- [ ] Lanjutkan alur *Decision Tree* (Sama seperti Google):
  1. Coba `FindByGithubID`. Jika ketemu → Login.
  2. Jika tidak, coba `FindByEmail`. Jika ketemu → `LinkGithubID` → Login.
  3. Jika tidak ketemu sama sekali → `CreateUser` (tanpa password, AuthProvider="github") → Login.

---

## FASE 2: Platform Setup (GitHub & Flutter)

### 1. GitHub Developer Settings
- [ ] Buka GitHub 👉 Settings 👉 Developer Settings 👉 OAuth Apps.
- [ ] Buat *New OAuth App*.
- [ ] Masukkan *Homepage URL* dan *Authorization callback URL* (Misal: `newsapp://callback` atau URL backend).
- [ ] Simpan `Client ID` dan `Client Secret`.

### 2. Flutter Setup
- [ ] Gunakan package dari Firebase `firebase_auth` (Jika integrasi via Firebase) ATAU package pihak ketiga seperti `oauth2_client` / `desktop_webview_auth`.
  *Catatan: GitHub tidak memiliki SDK spesifik yang se-native GoogleSignIn, umumnya menggunakan Webview popup.*

---

## FASE 3: Frontend (Flutter)

### 1. Domain Layer
- [ ] Update `abstract class OAuthProvider` (sudah dirancang sebelumnya) jika diperlukan.

### 2. Data Layer
- [ ] Buat `GithubOAuthProvider` yang meng-implement `OAuthProvider`.
  - Class ini akan membuka Webview/Safari untuk login ke GitHub dan menangkap `accessToken`.
- [ ] Pastikan memanggil HTTP `POST /api/v1/auth/oauth` dengan tipe provider `github`.

### 3. Presentation Layer (BLoC & UI)
- [ ] Tambahkan tombol "Lanjutkan dengan GitHub" di `LoginPage`.
- [ ] Hubungkan tombol ke `AuthBloc` (event `AuthOAuthLoginRequested` dengan provider `github`).
