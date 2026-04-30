# Authentication Feature

## Overview
Modul Auth bertugas mengelola siklus hidup _user authentication_. 

### 1. State Management (AuthBloc)
Modul otentikasi menggunakan `AuthBloc` yang sengaja dirancang sebagai **Global Singleton (`registerLazySingleton`)**. Kenapa demikian?

#### Mengapa Global Singleton?
Status "Login" seorang pengguna memengaruhi hampir seluruh bagian aplikasi (bukan cuma satu halaman). Kita butuh **satu _Source of Truth_ (Sumber Sentral)** yang otentik.
- Agar **GoRouter** di seluruh penjuru aplikasi bisa mendengarkan apakah dia harus memblokir jalur ke halaman terlarang.
- Agar **Interceptor API** bisa menyuntikkan token dari _session_ yang aktif, atau melakukan _logout_ otomatis bila Refresh Token tertolak.

#### Inisialisasi & Lifecycle
- **Registrasi**: `AuthBloc` didaftarkan di dalam `lib/injection_container.dart` (oleh GetIt) sebagai _LazySingleton_. 
- **Inisialisasi**: Fisik `AuthBloc` ditempatkan ke _Widget Tree_ tertinggi menggunakan `BlocProvider<AuthBloc>.value(value: sl<AuthBloc>())` di dalam file `main.dart`, di dalam `MultiBlocProvider` yang membungkus `MaterialApp.router`.
- **Siklus Hidup (Lifecycle)**: Karena BLoC ini dideklarasikan di puncak UI teratas, ia dikategorikan sebagai **Residen Abadi**. Ia lahir saat aplikasi dibuka dan baru akan mati (hancur) apabila pengguna menutup paksa *(Force Close)* aplikasi. Selama app berjalan, state *(User Profile + Token)* di dalam `AuthBloc` akan terus menetap di RAM.

**Event yang Tersedia**: 
`AuthCheckRequested`, `AuthLoginRequested`, `AuthRegisterRequested`, `AuthLogoutRequested`, `AuthProfileRequested`, `AuthUserUpdated`.

> **`AuthUserUpdated`** adalah event khusus yang dilempar oleh `ProfileCubit` setelah berhasil update profil — agar data User di `AuthBloc` (global) ikut ter-refresh tanpa perlu logout dan login ulang.

### 2. Network & Token
- Penyimpanan Token secara aman via `FlutterSecureStorage` (di `SecureTokenStorage`).
- Interceptor otomatis untuk `dio` agar header `Authorization: Bearer <token>` disuntikkan di setiap permintaan API.
- Terdapat logika penanganan `401 Unauthorized` dengan Refresh Token tersentralisasi di `ApiClient`.

### 3. Profile Management
- Integrasi `ProfileCubit` tingkat komponen (Local cubit) untuk pengeditan dan manipulasi state UI secara *ephemeral*.

---

## Technology Stack

| Teknologi | Package / API | Versi | Peran dalam Fitur |
|---|---|---|---|
| **State Management (Global)** | `flutter_bloc` → `BLoC` | ^9.1.0 | `AuthBloc` sebagai Global Singleton. Mengelola seluruh siklus hidup autentikasi: status login, data user, dan token. |
| **State Management (Local)** | `flutter_bloc` → `Cubit` | ^9.1.0 | `ProfileCubit` untuk mengelola state UI ephemeral di halaman Edit Profile (loading, sukses, gagal). |
| **Dependency Injection** | `get_it` | ^8.0.3 | Mendaftarkan `AuthBloc` sebagai `LazySingleton` dan semua layer (Repository, DataSource, Cubit) agar bisa dipanggil via `sl<T>()`. |
| **Routing & Guard** | `go_router` | ^14.8.1 | Mendengarkan perubahan state `AuthBloc` via `refreshListenable` untuk melakukan redirect otomatis (login → dashboard, atau sebaliknya). |
| **Secure Token Storage** | `flutter_secure_storage` | ^9.2.4 | Menyimpan `accessToken` dan `refreshToken` secara aman di Keychain (iOS) / Keystore (Android). |
| **HTTP Client** | `dio` | ^5.7.0 | Mengirimkan request `POST /login`, `POST /register`, `GET /profile`, dan `POST /refresh-token`. |
| **Auth Interceptor** | `dio` → `Interceptor` | ^5.7.0 | Menyuntikkan header `Authorization: Bearer <token>` secara otomatis di setiap request, dan menangani `401 Unauthorized` dengan mekanisme silent refresh token. |
| **Functional Error Handling** | `dartz` | ^0.10.1 | `Either<Failure, T>` digunakan di seluruh layer Repository untuk merepresentasikan hasil sukses atau gagal tanpa menggunakan `try-catch` di UI. |
| **Social Login (Google)** | `google_sign_in` | ^7.2.0 | Menjalankan SDK Native Google (Android/iOS) untuk memunculkan Account Picker dan mengambil `idToken` secara aman. |

---

## Architecture Sequence Diagrams

### 1. Login & Global Routing Flow
Diagram ini menggambarkan bagaimana eksekusi login mengalir dari layar UI menembus lapisan data terdalam, hingga akhirnya *Global State* merespon dengan melempar *Redirect* melalui GoRouter.

```mermaid
sequenceDiagram
    participant UI as LoginPage
    participant Router as GoRouter
    participant Bloc as AuthBloc
    participant Repo as AuthRepositoryImpl
    participant API as ApiClient
    participant Store as FlutterSecureStorage

    UI->>Bloc: add(AuthLoginRequested(email, password))
    Bloc->>Repo: login(email, password)
    Repo->>API: POST /login
    API-->>Repo: Token Response JSON
    
    Repo->>Store: saveToken(accessToken, refreshToken)
    
    Repo->>API: GET /profile (using new token)
    API-->>Repo: Profile JSON
    Repo-->>Bloc: return User Entity
    
    Bloc-->>UI: emit(AuthStatus.authenticated)
    
    Note over Router,Bloc: Router mendengarkan refreshListenable
    Bloc-->>Router: notifyListeners()
    Router-->>UI: Auto-Redirect to /dashboard
```

### 2. Auto-Refresh Token Flow (Interceptor)
Mekanisme pertahanan (*defense*) ketika _Access Token_ kadaluarsa. Diagram ini menjelaskan bagaimana Interceptor mencegat (*intercept*) masalah 401 dan secara diam-diam (*silent*) memperbarui sesi pengguna tanpa merusak UX.

```mermaid
sequenceDiagram
    participant UI as Any Feature Cubit
    participant API as ApiClient
    participant Intercept as AuthInterceptor
    participant Backend as Server

    UI->>API: fetchNewsFeed()
    API->>Intercept: onRequest (Inject Token A)
    Intercept->>Backend: HTTP GET /news (Token A)
    
    Backend-->>Intercept: 401 Unauthorized (Token Expired)
    
    Intercept->>Intercept: Pause Queue!
    Intercept->>Backend: HTTP POST /refresh (using RefreshToken)
    
    alt Refresh Sukses
        Backend-->>Intercept: New Token B
        Intercept->>FlutterSecureStorage: Update Token B
        Intercept->>Backend: RETRY HTTP GET /news (Token B)
        Backend-->>API: 200 OK
        API-->>UI: News Data
    else Refresh Gagal / RefreshToken Expired
        Backend-->>Intercept: 401 Unauthorized
        Intercept->>AuthBloc: add(AuthLogoutRequested())
        Intercept-->>API: throw UnauthorizedException
        API-->>UI: Emit Error State
    end
```

### 3. Repository Orchestration Flow (Profile Fallback)
Di dalam `AuthRepositoryImpl`, tersimpan logika cerdas yang bertindak sebagai _Orchestrator_. Saat melempar request profil (misalnya saat _Splash Screen_ atau buka aplikasi di area _blank spot_), aplikasi harus bisa bertahan *(Graceful Degradation)*.

Berikut adalah algoritma _Flowchart_ bagaimana Repository menjembatani kegagalan jaringan dengan menarik data sisa *(fallback)* dari cache lokal:

```mermaid
flowchart TD
    Start([Start: AuthRepository.getProfile]) --> TryRemote[1. Coba fetch dari RemoteDatasource]
    
    TryRemote --> IsRemoteSuccess{API Sukses?}
    
    %% Baris Sukses (Happy Path)
    IsRemoteSuccess -- "Ya (HTTP 200)" --> SaveCache[2. Timpa / Save ke LocalDatasource]
    SaveCache --> ReturnRemote([3. Return Data Profil Baru])
    
    %% Baris Gagal (Fallback)
    IsRemoteSuccess -- "Gagal (Koneksi Mati / Server Error)" --> TryLocal[2. Coba tarik data dari LocalDatasource]
    
    TryLocal --> IsLocalExists{Cache Tersedia?}
    
    IsLocalExists -- "Ya (Ada Sisa Data)" --> ReturnLocal([3. Return Data Profil Lawas / Cache])
    IsLocalExists -- "Tidak (Kosong / null)" --> ReturnError([3. Return Failure / Error])

    classDef success fill:#d4edda,stroke:#28a745,stroke-width:2px;
    classDef error fill:#f8d7da,stroke:#dc3545,stroke-width:2px;
    classDef warning fill:#fff3cd,stroke:#ffc107,stroke-width:2px;
    
    class ReturnRemote success;
    class ReturnLocal warning;
    class ReturnError error;
```

---

## Login Methods

Aplikasi mendukung dua jenis metode login yang memiliki alur berbeda, namun berakhir di titik yang sama: mendapatkan JWT (accessToken + refreshToken) dari backend.

### Perbandingan Email/Password vs Social Login

| Aspek | Email & Password | Social Login (Google, dll) |
|-------|-----------------|-----------------------------|
| **Credential asal** | User input langsung di form | Provider eksternal (Google, Apple, GitHub) |
| **Yang dikirim ke BE** | `{ email, password }` | `{ provider, idToken }` |
| **Endpoint BE** | `POST /auth/login` | `POST /auth/oauth` |
| **Verifikasi di BE** | Cek hash password di DB | Verifikasi idToken ke server provider |
| **UI Popup** | Tidak ada | Native OS picker (bukan halaman Flutter baru) |
| **Halaman Flutter baru?** | Tidak | Tidak — semua tombol ada di `LoginPage` yang sama |
| **Status Implementasi** | ✅ Done | 🔄 Planned (Google Sign-In first) |

---

## Social Login — Rencana Implementasi

### Filosofi Desain: Extensible OAuth

Social Login dirancang dengan abstraksi `OAuthProvider` agar setiap provider baru (GitHub, Apple, Facebook) cukup menambah satu class implementasi tanpa mengubah BLoC, UseCase, atau Repository.

```
Domain Layer:
  abstract OAuthProvider
    └── getIdToken() → Future<String>

Data Layer:
  GoogleOAuthProvider  implements OAuthProvider
  GithubOAuthProvider  implements OAuthProvider  (future)
  AppleOAuthProvider   implements OAuthProvider  (future, App Store required)

UseCase:
  SocialLoginUseCase.call(OAuthProvider provider)
    → provider.getIdToken()
    → repository.loginWithOAuth(idToken, providerName)

AuthBloc:
  add(AuthSocialLoginRequested(provider: GoogleOAuthProvider()))
  add(AuthSocialLoginRequested(provider: GithubOAuthProvider()))   // future
```

> [!IMPORTANT]
> **Apple Sign-In wajib ada** jika app dipublish di App Store dan menawarkan social login provider lain. Ini adalah aturan App Store Review Guidelines — app bisa direject jika tidak ada.

### Diagram 4 — Google Sign-In Flow

Berbeda dengan login email/password yang langsung mengirim credential ke backend, Google Sign-In memerlukan langkah perantara: mendapatkan `idToken` dari Google terlebih dahulu.

```mermaid
sequenceDiagram
    actor User
    participant LP as LoginPage (Flutter)
    participant OS as Native OS (Google SDK)
    participant Bloc as AuthBloc
    participant Repo as AuthRepositoryImpl
    participant Google as Google API Server
    participant BE as Backend (Go)
    participant Store as FlutterSecureStorage
    participant Router as GoRouter

    User->>LP: Tap [G Lanjutkan dengan Google]
    LP->>Bloc: add(AuthSocialLoginRequested(GoogleOAuthProvider))
    Bloc->>OS: GoogleSignIn().signIn()
    Note over OS: Native Google Account Picker muncul
    Note over LP: LoginPage tetap di stack, kontrol di OS

    User->>OS: Pilih akun Google
    OS-->>Bloc: GoogleSignInAccount (idToken)

    Bloc->>Repo: loginWithOAuth(idToken, provider: 'google')
    Repo->>BE: POST /auth/oauth { provider, idToken }
    BE->>Google: Verifikasi idToken
    Google-->>BE: { email, name, googleId } valid

    alt User belum ada di DB
        BE->>BE: Buat user baru dari data Google
    else User sudah ada
        BE->>BE: Login langsung
    end

    BE-->>Repo: { accessToken, refreshToken, user }
    Repo->>Store: saveTokens(accessToken, refreshToken)
    Repo-->>Bloc: Right(User)

    Bloc->>Bloc: emit(AuthAuthenticated(user))
    Bloc-->>Router: notifyListeners()
    Router-->>LP: Auto-redirect ke /dashboard
```

### Diagram 5 — Perbandingan Alur: Email vs Google

```mermaid
graph TD
    A([User buka LoginPage]) --> B{Pilih metode login}

    B -->|Email & Password| C[Isi form email + password]
    C --> D[add AuthLoginRequested]
    D --> E[POST /auth/login]
    E --> F[BE verifikasi password hash]

    B -->|Google Sign-In| G[Tap tombol G]
    G --> H[Native OS Google Picker]
    H --> I[Pilih akun Google]
    I --> J[Dapat idToken dari Google SDK]
    J --> K[add AuthSocialLoginRequested]
    K --> L[POST /auth/oauth]
    L --> M[BE verifikasi idToken ke Google API]

    F --> N[BE return accessToken + refreshToken]
    M --> N

    N --> O[Simpan token ke SecureStorage]
    O --> P[emit AuthAuthenticated]
    P --> Q([GoRouter redirect /dashboard])
```

### Kebutuhan Setup per Platform

#### Flutter Side
- Tambah package `google_sign_in: ^6.x.x` di `pubspec.yaml`
- Tambah event `AuthSocialLoginRequested` di `AuthBloc`
- Buat `GoogleOAuthProvider` di Data Layer
- Buat `SocialLoginUseCase` di Domain Layer
- Tambah tombol Google di `LoginPage` (di bawah tombol login biasa)

#### Android
- Tambah SHA-1 fingerprint di Google Cloud Console
- Tambah `google-services.json` di `android/app/`
- Update `build.gradle` dengan Google Services plugin

#### iOS
- Tambah `REVERSED_CLIENT_ID` ke `Info.plist`
- Pastikan URL Scheme terdaftar

#### Backend (Go)
- Endpoint baru: `POST /api/v1/auth/oauth`
- Tambah library verifikasi Google ID Token
- Logic upsert user: buat jika belum ada, login jika sudah ada
- Return format sama dengan login biasa: `{ accessToken, refreshToken, user }`

#### Google Cloud Console
- Buat project baru atau gunakan yang existing
- Enable "Google Sign-In API"
- Buat OAuth 2.0 Client ID untuk Android dan iOS
- Daftarkan SHA-1 fingerprint

---

## Social Login Architecture Flow
Unlike the standard login flow where raw data (`email` and `password` strings) is passed from the UI down to the data layer, the Social Login flow passes a **Behavioral Object** (`OAuthService`). 

The UI creates the `OAuthService` object (e.g., `GoogleOAuthService`), but **does not execute it**. The object travels through the layers until it reaches the `AuthRepository`, which is responsible for "pulling the trigger" (`service.signIn()`) to execute the native SDK logic and fetch the token.

```mermaid
sequenceDiagram
    autonumber
    
    actor User
    participant UI as LoginPage (UI)
    participant Bloc as AuthBloc (Presentation)
    participant UC as SocialLoginUseCase (Domain)
    participant Repo as AuthRepositoryImpl (Data)
    participant Service as GoogleOAuthService (Data/SDK)
    participant Remote as AuthRemoteDataSource (Data)
    participant API as Go Backend API
    participant Local as AuthLocalDataSource (Data)

    User->>UI: Taps "Sign in with Google" button
    
    Note over UI, Bloc: 1. UI ONLY INSTANTIATES the service
    UI->>Bloc: add(AuthOAuthLoginRequested(GoogleOAuthService()))
    
    Bloc->>Bloc: emit(AuthStatus.loading)
    
    Note over Bloc, UC: 2. BLoC passes service to UseCase
    Bloc->>UC: call(GoogleOAuthService)
    
    Note over UC, Repo: 3. UseCase delegates to Repository
    UC->>Repo: signInWithOAuth(GoogleOAuthService)
    
    rect rgb(255, 243, 205)
        Note over Repo, Service: 4. THE TRIGGER! Repository fires the SDK
        Repo->>Service: ⚡️ await service.signIn()
        
        Service-->>User: Displays Google Account Picker (Native UI)
        User->>Service: Selects Google Account
        
        Service-->>Repo: 🔑 RETURNS idToken (JWT from Google SDK)
    end
    
    Note over Repo, Remote: 5. Exchange token with Backend
    Repo->>Remote: signInWithOAuth(provider: 'google', idToken)
    
    Remote->>API: POST /api/v1/auth/oauth {provider, id_token}
    API-->>Remote: Returns AuthTokens (accessToken, refreshToken)
    Remote-->>Repo: Returns AuthTokensModel
    
    Note over Repo, Local: 6. Save tokens securely
    Repo->>Local: saveTokens(accessToken, refreshToken)
    
    Repo-->>UC: Right(AuthTokens)
    UC-->>Bloc: Right(AuthTokens)
    
    Note over Bloc, API: 7. BLoC automatically fetches user profile
    Bloc->>API: Fetch Profile
    API-->>Bloc: Returns UserModel
    
    Bloc->>UI: emit(AuthStatus.authenticated, user)
    UI-->>User: Navigates to Dashboard
```

---

## Forgot Password (Lupa Password) — Rencana Implementasi

Fitur **Lupa Password** menggunakan mekanisme pendelegasian keamanan melalui **Firebase Phone Auth (OTP SMS)**. Dengan cara ini, aplikasi Flutter dan Backend Go tidak perlu mengelola server SMS gateway atau menyimpan kode OTP.

### Alur Arsitektur Kriptografi

1.  **Aplikasi Flutter (Client)**: Bertugas meminta SMS ke Firebase, memunculkan form input angka OTP, dan mengirimkan kode tersebut ke Firebase SDK untuk divalidasi.
2.  **Firebase SDK (Google)**: Jika OTP benar, SDK ini mencetak sebuah `idToken` (surat lulus verifikasi yang ditandatangani secara digital oleh Google).
3.  **Backend Go (Server)**: Menerima `idToken` dari Flutter, memverifikasi tanda tangannya menggunakan kunci publik Google, lalu mengizinkan ubah password jika token valid.

### Sequence Diagram — Lupa Password Flow (Clean Architecture)

Mengikuti standar *Clean Architecture* aplikasi ini, fitur yang bersifat *ephemeral* (berlangsung sementara di satu halaman) tidak boleh mengotori *Global State* (`AuthBloc`). Oleh karena itu, fitur ini akan dilayani oleh **`ForgotPasswordCubit`** lokal dan dijembatani oleh *UseCase*.

**Lapisannya:** `UI` ➔ `ForgotPasswordCubit` ➔ `UseCase` ➔ `AuthRepositoryImpl` ➔ `FirebaseOTPService` & `ApiClient`.

```mermaid
sequenceDiagram
    actor User
    participant UI_Phone as ForgotPasswordPhonePage
    participant UI_OTP as ForgotPasswordOTPPage
    participant UI_Reset as ForgotPasswordResetPage
    participant Cubit as ForgotPasswordCubit
    participant Repo as AuthRepositoryImpl
    participant FBService as FirebaseOTPService
    participant BE as Go Backend API

    Note over User, BE: FASE 1: Meminta OTP (Request OTP)
    User->>UI_Phone: Input Nomor HP (+62...)
    UI_Phone->>Cubit: requestOTP(phone)
    Cubit->>Repo: requestOTP(phone)
    Repo->>FBService: verifyPhoneNumber(phone)
    FBService-->>User: SMS OTP Terkirim oleh Google
    FBService-->>Repo: Returns `verificationId`
    Repo-->>Cubit: Right(verificationId)
    Cubit->>Cubit: Simpan `verificationId` di State
    Cubit->>UI_Phone: emit(ForgotPasswordState.otpSent)
    UI_Phone-->>User: Navigasi ke Halaman OTP
    
    Note over User, BE: FASE 2: Verifikasi OTP
    User->>UI_OTP: Input 6 digit OTP
    UI_OTP->>Cubit: verifyOTP(otp)
    Cubit->>Repo: verifyOTP(verificationId, otp)
    
    rect rgb(255, 243, 205)
        Note over Repo, FBService: Menukar OTP menjadi JWT Firebase
        Repo->>FBService: signInWithCredential(verificationId, otp)
        FBService-->>Repo: 🔑 Returns `firebase_id_token`
    end
    
    Repo-->>Cubit: Right(firebase_id_token)
    Cubit->>Cubit: Simpan `firebase_id_token` di State
    Cubit->>UI_OTP: emit(ForgotPasswordState.otpVerified)
    UI_OTP-->>User: Navigasi ke Halaman Reset Password
    
    Note over User, BE: FASE 3: Set Password Baru
    User->>UI_Reset: Input Password Baru
    UI_Reset->>Cubit: submitNewPassword(newPassword)
    Cubit->>Repo: resetPassword(firebase_id_token, newPassword)
    
    Note over Repo, BE: Kirim ke Backend untuk Validasi Kriptografi
    Repo->>BE: POST /api/v1/auth/password/forgot {idToken, newPassword}
    BE->>BE: Verifikasi Kriptografi Token & Update DB
    BE-->>Repo: 200 OK (Success)
    
    Repo-->>Cubit: Right(Success)
    Cubit->>UI_Reset: emit(ForgotPasswordState.success)
    UI_Reset-->>User: Tampilkan SnackBar Sukses, kembali ke LoginPage
```

### Kebutuhan Setup Flutter
- Penambahan package `firebase_auth` ke `pubspec.yaml`.
- Menggunakan `TextField` dengan `autofillHints: const [AutofillHints.oneTimeCode]` agar OTP dari SMS bisa otomatis dibaca oleh *keyboard* iOS dan Android tanpa perlu *permission* baca SMS.
- Registrasi SHA-1 & SHA-256 Android di Firebase Console.
- Konfigurasi APNs & Background Modes di iOS untuk penerimaan *Silent Push* dari Firebase (sebagai langkah anti-spam).
