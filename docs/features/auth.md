# Authentication Feature

## Overview
Modul Auth bertugas mengelola siklus hidup _user authentication_. 

### 1. State Management (AuthBloc)
- Bertindak sebagai _Global Singleton_ yang mengatur status login secara global.
- Event yang ada: `AuthCheckRequested`, `AuthLoginRequested`, `AuthRegisterRequested`, `AuthLogoutRequested`.
- Didaftarkan di `main.dart` untuk memastikan navigasi _GoRouter_ mengetahui kapan harus mencegah akses masuk (`redirect`).

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
