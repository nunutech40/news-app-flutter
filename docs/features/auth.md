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
- **Inisialisasi**: Fisik `AuthBloc` ditiupkan rohnya ke _Widget Tree_ _tertinggi_ (di akar layar) menggunakan `BlocProvider(create: (_) => sl<AuthBloc>())` di dalam file `main.dart`, persis membungkus `MaterialApp.router`.
- **Siklus Hidup (Lifecycle)**: Karena BLoC ini dideklarasikan di puncak UI teratas, ia dikategorikan sebagai **Residen Abadi**. Ia lahir saat aplikasi dibuka dan baru akan mati (hancur) apabila pengguna menutup paksa *(Force Close)* aplikasi. Selama app berjalan, state *(User Profile + Token)* di dalam `AuthBloc` akan terus menetap di RAM.

**Event yang Tersedia**: 
`AuthCheckRequested`, `AuthLoginRequested`, `AuthRegisterRequested`, `AuthLogoutRequested`.

### 2. Network & Token
- Penyimpanan Token secara aman via `FlutterSecureStorage` (di `SecureTokenStorage`).
- Interceptor otomatis untuk `dio` agar header `Authorization: Bearer <token>` disuntikkan di setiap permintaan API.
- Terdapat logika penanganan `401 Unauthorized` dengan Refresh Token tersentralisasi di `ApiClient`.

### 3. Profile Management
- Integrasi `ProfileCubit` tingkat komponen (Local cubit) untuk pengeditan dan manipulasi state UI secara *ephemeral*.

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
