# News & Explore Features

## Overview
Modul News dan Explore adalah jantung dari penemuan konten dalam aplikasi ini. 

### 1. Arsitektur Komponen Bersama (Shared Architecture Tree)

Keunikan terbesar modul ini bermuara pada akar efisiensinya. Meski layar memiliki **2 Tab Berbeda** (News & Explore) yang dihidupi oleh **4 Cubit Berbeda**, mereka semua diam-diam merujuk dan "menyedot" data dari **Satu UseCase dan Repository yang Sama**.
Pendekatan ini menjamin satu sumber kebenaran (*Single Source of Truth*) dan mencegah duplikasi kode.

```mermaid
graph TD
    classDef ui fill:#fdf4fb,stroke:#da70d6,stroke-width:2px;
    classDef cubit fill:#e3f2fd,stroke:#2196f3,stroke-width:2px;
    classDef domain fill:#e8f5e9,stroke:#4caf50,stroke-width:2px;
    classDef data fill:#fff3e0,stroke:#ff9800,stroke-width:2px;

    %% UI Pages
    NewsPage(News Tab UI):::ui
    ExplorePage(Explore Tab UI):::ui
    
    %% Cubits
    CatCubit[CategoryCubit]:::cubit
    TrendCubit[TrendingCubit]:::cubit
    FeedCubit[NewsFeedCubit]:::cubit
    ExpCubit[ExploreCubit]:::cubit

    %% Wiring UI to Cubits
    NewsPage --> CatCubit
    NewsPage --> TrendCubit
    NewsPage --> FeedCubit
    ExplorePage --> ExpCubit

    %% The Shared Core
    UseCase((GetNewsFeedUseCase)):::domain
    Repo{NewsRepositoryImpl}:::data
    
    %% Wiring Cubits to UseCase
    CatCubit -.Tidak pakai UseCase Feed.-> X
    TrendCubit ==>|includeHero: true| UseCase
    FeedCubit ==>|page: N| UseCase
    ExpCubit ==>|3x API calls, categories| UseCase

    UseCase ===> Repo
```

---

### 2. News Tab Feature (Beranda)
News tab bertugas menampilkan berita utama menggunakan strategi **Composite Bloc**.

#### 2.1 Paradigma "Composite" Cubit (Banyak State)
Layar `NewsPage` sengahja dipecah paksa menjadi 3 Cubit berbeda (`CategoryCubit`, `TrendingCubit`, `NewsFeedCubit`).
- **Alasan Utama (Isolasi Render):** Setiap sub-bagian layar punya laju perubahan yang ekstrem. *NewsFeed* sering memuat halaman baru, sementara *Trending* statis. Jika digabung menjadi 1 raksasa `NewsCubit`, saat *User* me-load halaman kedua berita, *seluruh Carousel Trending akan ikut di-render ulang!* 
- Dengan memecahnya, *Flutter* hanya me-re-paint pecahan kecil layar yang benar-benar berubah, mengunci *Frame Rate* di 60 FPS.

#### 2.2 Diagram: Pagination Flow (Load More)
Ini adalah siklus bagaimana `NewsFeedCubit` bertumbuh secara bertahap menjaga efisiensi RAM, memuat halaman baru hanya jika pengguna melakukan *scroll* mendalam.

```mermaid
sequenceDiagram
    participant Scroll as ScrollController
    participant Cubit as NewsFeedCubit
    participant UC as GetNewsFeedUseCase
    participant API as Backend (Page N)

    Scroll->>Cubit: LoadMore() triggered at end of list
    
    %% Guard Closes
    Cubit->>Cubit: Cek: Apakah isFetchingMore == true?
    alt Sedang memuat
        Cubit-->>Scroll: Abaikan (Pencegahan request ganda)
    else Belum memuat & currentPage < totalPages
        Cubit->>Cubit: isFetchingMore = true
        Cubit-->>Scroll: emit(Munculkan Loading Bawah)
        
        Cubit->>UC: fetch(page: currentPage + 1)
        UC->>API: GET /feed?page=N+1
        
        API-->>UC: Response (List Berita Baru)
        UC-->>Cubit: Left/Right
        
        alt Sukses
            Cubit->>Cubit: Gabungkan berita lama + Baru (List.addAll)
            Cubit->>Cubit: currentPage = currentPage + 1
            Cubit-->>Scroll: emit(LoadedState with larger List)
        else Gagal
            Cubit-->>Scroll: emit(Error tapi List lama tetap aman)
        end
        Cubit->>Cubit: isFetchingMore = false
    end
```

---

### 3. Explore Tab Feature (Jelajah)
Explore tab dirancang sebagai aggregator asinkron paralel. Tidak menggunakan Repository/UseCase khusus, melainkan memakai ulang `GetNewsFeedUseCase`.

#### 3.1 Paradigma "Monolithic" Cubit (Satu Penampung)
Berbeda dengan Tab Beranda, Jelajah memaksa menggunakan 1 `ExploreCubit` tunggal untuk menampung isi perut 3 *List* Berita (`Tech`, `Business`, `Sports`) di dalam wadah state yang sama.
- **Alasan Utama (Orkestrasi Waktu):** Syarat UX layar Jelajah adalah memunculkan ketiganya secara berurutan *(staggered/kaskade)*. Jika menggunakan 3 Cubit berbeda, kita akan kesulitan setengah mati menyinkronkan waktu loading mereka. Dengan 1 Cubit Penguasa, satu buah fungsi *async* memegang stopwatch penuh mengontrol penayangan UI secara harmonis.

#### 3.2 Diagram: Staggered Parallel Orchestration
Ini adalah visualisasi bagaimana `ExploreCubit` memanggil 3 request ke server **secara bersamaan (paralel)**, tetapi menyajikan hasilnya ke layar secara **berurutan (kaskade)** untuk efek UX *Pop-In* menggunakan *Artificial Delay*.

```mermaid
sequenceDiagram
    participant UI as ExplorePage
    participant Cubit as ExploreCubit
    participant UC as GetNewsFeedUseCase
    participant API as Backend Server

    UI->>Cubit: loadAllSections()
    Cubit->>Cubit: emit(Loading)
    
    note over Cubit,API: Memulai 3 Request Paralel (Future.wait)
    
    par Tech Category
        Cubit->>UC: fetch(category: 'tech')
        UC->>API: GET /feed?category=tech
    and Business Category
        Cubit->>UC: fetch(category: 'business')
        UC->>API: GET /feed?category=business
    and Sports Category
        Cubit->>UC: fetch(category: 'sports')
        UC->>API: GET /feed?category=sports
    end

    %% Response handling with artificial delays
    API-->>UC: Response (Tech)
    UC-->>Cubit: Left/Right
    Cubit->>Cubit: (await 400ms delay)
    Cubit-->>UI: emit(Tech Loaded) - Kartu 1 Muncul!
    
    API-->>UC: Response (Business)
    UC-->>Cubit: Left/Right
    Cubit->>Cubit: (await 800ms delay)
    Cubit-->>UI: emit(Business Loaded) - Kartu 2 Muncul!
    
    API-->>UC: Response (Sports)
    UC-->>Cubit: Left/Right
    Cubit->>Cubit: (await 1200ms delay)
    Cubit-->>UI: emit(Sports Loaded) - Kartu 3 Muncul!
```

---

## 3. Strategi Siklus Hidup (Initialization & Lifecycle)

Pertanyaan penting dalam arsitektur berskala besar: *"Di mana Cubit dan UseCase ini diciptakan, dan mengapa ditaruh di sana?"*
NewsApp menerapkan manajemen memori yang ketat dengan kombinasi GetIt (Pabrik) dan BlocProvider (Siklus Hidup).

#### A. Warga Abadi: `UseCases` (GetNewsFeedUseCase, dkk)
- **Registrasi**: Didaftarkan sebagai **`registerLazySingleton`** di `injection_container.dart`.
- **Alasan**: `UseCase` itu wujudnya murni hanya kumpulan Fungsi/Rumus Bisnis tanpa wujud UI. Karena ia bersih dari variabel *State*, tidak masuk akal memboroskan RAM untuk mencetak `UseCase` berulang-ulang setiap kali buka layar. Cukup 1 untuk seluruh aplikasi.

#### B. Warga Sementara: Sepasukan `Cubits` (NewsFeedCubit, ExploreCubit, dkk)
- **Registrasi Pabrik**: Didaftarkan sebagai **`registerFactory`** di `injection_container.dart`. Ini berarti bentuknya hanya cetak biru. GetIt tidak akan menaruhnya di Memori Utama.
- **Inisialisasi Fisik (Lahir)**: Berpasukan Cubit ini (bersama dengan *Trending, Category,* dan *Bookmark*) ditiupkan roh fisiknya serentak di dalam **`app_router.dart`** yang membungkus `/dashboard` menggunakan `MultiBlocProvider`.
- **Alasan Mengapa di Router Dashboard?**
  Berbalik dengan `AuthBloc` yang hidup abadi di atas, kumpulan Cubit Berita ini HARUS bersifat Fana (Terbatas). Kenapa?
  1. Mereka memuat **Data Rahasia Sesi (State UI)** seperti daftar artikel, halaman 5, dan cache beranda.
  2. Saat User Log Out (kembali ke `/login`), seluruh Rute `/dashboard` akan DITEBAS dari tumpukan router.
  3. Konsekuensi luar biasanya: Semua tumpukan Cubit ini akan ikut gugur, dan _Garbage Collector_ HP akan menguras RAM hingga kosong bersih. Tidak ada lagi data lama yang tersisa jika sewaktu-waktu ada User baru _Login_!

---

## 4. Offline-First & Caching Strategy

Dokumen ini menjelaskan strategi *Graceful Degradation* untuk fitur News Feed sehingga aplikasi tetap bisa menampilkan data dan tidak kosong melompong saat perangkat pengguna offline atau jaringan bermasalah.

### 3.1 Konsep Utama
Alih-alih menyimpan seluruh database berita (yang akan memakan banyak Storage memori pengguna), aplikasi **hanya menyimpan (cache) halaman pertama (Page 1) dari feed berita utama (Kategori 'All')**. 

*   **Target Penyimpanan**: `SharedPreferences` (dalam bentuk JSON Text / String).
*   **Triggers**:
    *   **Write**: Saat HTTP response sukses dari endpoint `getFeed(page: 1, category: null)`.
    *   **Read**: Saat `ApiClient` melempar `NetworkException` dalam upaya memuat endpoint `getFeed(page: 1, category: null)`.

### 3.2 Alur Eksekusi (Orchestration)
Implementasi ini ditangani langsung di repositori data (`NewsRepositoryImpl`), menjadikannya sebagai _Smart Orchestrator_.

```mermaid
sequenceDiagram
    participant UI as NewsFeedCubit
    participant Repo as NewsRepositoryImpl
    participant Local as NewsLocalDatasource
    participant Remote as NewsRemoteDatasource
    participant API as Backend API

    UI->>Repo: getFeed(page: 1, category: null)
    Repo->>Remote: fetchFeed(1, null)
    
    alt Internet Normal (Happy Path)
        Remote->>API: HTTP GET
        API-->>Remote: HTTP 200 OK
        Remote-->>Repo: JSON Map
        Repo->>Local: cacheNewsFeed(JSON Map)
        Repo-->>UI: Return Record(Hero, Feed, TotalPages)
    else Internet Mati (NetworkException)
        Remote-xAPI: Failed to connect
        Remote-->>Repo: throw NetworkException
        Repo->>Local: getCachedNewsFeed()
        
        alt Cache Tersedia
            Local-->>Repo: Cached JSON Map
            Repo-->>UI: Return Record (Cached Data)
        else Cache Kosong
            Local-->>Repo: null
            Repo-->>UI: re-throw NetworkException
        end
    end
```

### 3.3 Komponen yang Terlibat

#### A. `NewsLocalDatasource` (Baru)
Antarmuka baru yang berinteraksi dengan `SharedPreferences`:
```dart
abstract class NewsLocalDatasource {
  Future<void> cacheNewsFeed(Map<String, dynamic> rawJson);
  Future<Map<String, dynamic>?> getCachedNewsFeed();
}
```
*Gunakan `jsonEncode` untuk menyimpan dan `jsonDecode` saat mengambil data.*

#### B. `NewsRepositoryImpl` (Modifikasi)
Repository menyuntikkan Local Datasource dan mencegat `NetworkException` khusus untuk pencarian `page == 1 && category == null`.

### 3.4 Keuntungan Pendekatan Ini
1. **Performa Tinggi**: Ukuran string JSON 1 halaman berita (< 200KB) sangat kecil untuk diurai (parse).
2. **Efisiensi Penyimpanan**: User tidak dibebani ukuran app membengkak seiring waktu karena data selalu ditimpa (overwrite).
3. **User Experience**: Layar tidak pernah blank saat pertama buka app sambil masuk ke dalam lift bus train atau daerah susah sinyal.


