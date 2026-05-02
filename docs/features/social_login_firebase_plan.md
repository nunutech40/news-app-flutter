# Eksekusi Plan: Unified Social Login (GitHub & X/Twitter) via Firebase

Dokumen ini memuat rencana eksekusi untuk mengimplementasikan fitur Social Login menggunakan **GitHub** dan **X (Twitter)** secara serentak menggunakan **Firebase Auth** sebagai jembatan penengah (Identity Hub).

---

## 🔥 ARSITEKTUR BARU: "FIREBASE SEBAGAI CALO"

Jika kita murni mendelegasikan GitHub dan X ke Firebase Auth, arsitektur kita berubah menjadi **jauh lebih elegan dan simpel**!

**Bagaimana cara kerjanya?**
1. User tap tombol GitHub atau X di aplikasi Flutter.
2. Firebase Auth membuka Webview/Browser, mengurus OAuth 2.0 *callback*, *access token*, dan *client secret* dengan GitHub/X.
3. Setelah GitHub/X menyatakan valid, **Firebase akan menerbitkan 1 token universal: `Firebase ID Token` (JWT)**.
4. Aplikasi Flutter HANYA mengirim `Firebase ID Token` tersebut ke Backend Go kita.
5. Backend Go **TIDAK PERLU LAGI** ngurusin API GitHub atau API X! Backend Go hanya perlu ngecek apakah `Firebase ID Token` itu asli atau palsu menggunakan Firebase Admin SDK (seperti saat fitur Lupa Password).

**Kesimpulan:** 
Backend Go Anda menjadi buta huruf terhadap provider. Dia cuma tahu: *"Oh, ini token valid dari Firebase, silakan masuk!"*. Urusan tarik-menarik *access token* sepenuhnya dibebankan ke server Firebase.

---

## FASE 1: Setup Console (Firebase, GitHub, X)
*(Di sinilah Anda harus setup satu per satu, tapi hanya sekali seumur hidup)*

### 1. Setup GitHub Developer
- Masuk ke GitHub Developer Settings 👉 OAuth Apps 👉 New OAuth App.
- **Authorization callback URL:** Copy-paste link dari Firebase Console (biasanya `https://<PROJECT_ID>.firebaseapp.com/__/auth/handler`).
- Ambil `Client ID` dan `Client Secret`.
- Buka **Firebase Console 👉 Authentication 👉 Sign-in method 👉 GitHub**, lalu masukkan ID & Secret tersebut. Enable.

### 2. Setup X (Twitter) Developer
- Masuk ke Twitter Developer Portal 👉 Projects & Apps.
- Set up App Authentication.
- **Callback URI:** Copy-paste link dari Firebase Console.
- Ambil `API Key` dan `API Key Secret`.
- Buka **Firebase Console 👉 Authentication 👉 Sign-in method 👉 Twitter**, lalu masukkan Key & Secret tersebut. Enable.

---

## FASE 2: Backend (Go)

### 1. Database Migration
- [ ] Buat file migrasi baru: `free-api-news/migrations/012_add_firebase_uid.sql`.
- [ ] Tambahkan kolom `firebase_uid VARCHAR(255) UNIQUE`. (Menggantikan ide bikin kolom `google_id`, `github_id`, `twitter_id` yang terpisah-pisah).

### 2. Update Model & Repository
- [ ] Update `models.User` struct untuk menerima `FirebaseUID` dan `AuthProvider`.
- [ ] Tambah fungsi `FindByFirebaseUID(uid string) (*models.User, error)`.

### 3. Service Logic (`AuthService`)
- [ ] Update `AuthService.OAuthLogin`:
  1. Terima `idToken` (Firebase JWT) dari Flutter.
  2. Verifikasi token pakai `firebaseAuthClient.VerifyIDToken(ctx, idToken)`.
  3. Ekstrak `UID`, `Email`, `Name` dari token Firebase.
  4. Coba `FindByFirebaseUID`. Jika ketemu → Login sukses.
  5. Jika tidak ketemu, coba `FindByEmail`. Jika ketemu → Update kolom `firebase_uid` → Login sukses.
  6. Jika tidak ketemu sama sekali → `CreateUser` (tanpa password) → Login sukses.

*(Notice: Tidak ada HTTP GET ke api.github.com atau api.twitter.com di Backend Go! Semua data sudah dibungkus di dalam token Firebase).*

---

## FASE 3: Frontend (Flutter)

### 1. Data Layer (`OAuthProvider` implementations)
- [ ] Buat `GithubOAuthProvider` di Flutter:
  ```dart
  final provider = GithubAuthProvider();
  final userCredential = await FirebaseAuth.instance.signInWithProvider(provider);
  final firebaseIdToken = await userCredential.user!.getIdToken();
  return firebaseIdToken; // Kirim ini ke Backend Go!
  ```
- [ ] Buat `TwitterOAuthProvider` di Flutter:
  ```dart
  final provider = TwitterAuthProvider();
  final userCredential = await FirebaseAuth.instance.signInWithProvider(provider);
  final firebaseIdToken = await userCredential.user!.getIdToken();
  return firebaseIdToken; // Kirim ini ke Backend Go!
  ```

### 2. Presentation Layer
- [ ] Tambahkan tombol "Lanjutkan dengan GitHub" dan "Lanjutkan dengan X" di `LoginPage`.
- [ ] Hubungkan tombol ke `AuthBloc` (event `AuthOAuthLoginRequested` dengan provider masing-masing).
