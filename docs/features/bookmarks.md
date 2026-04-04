# Bookmarks & Detail Feature

## Overview
Modul Bookmark dirancang dengan filosofi **100% Offline-First**. Penyimpanan artikel favorit tidak memerlukan koneksi internet maupun sinkronisasi (*API Call*) ke backend. Data hidup secara independen di dalam perangkat pengguna.

### 1. State Management (BookmarkCubit)
- Beroperasi sebagai pengelola *List* kumpulan artikel.
- Karena bersifat lokal, fitur *Bookmark* memberikan rasa Instan 0 detik *Delay* (tanpa Spinner Loading sama sekali).
- Diinisialisasi di `app_router.dart` (`DashboardPage`) agar status "Tersimpan/Tidak" tersinkronisasi mulus saat pengguna berpindah tab antar *News* dan *Explore*.

### 2. Article Detail (ArticleDetailCubit)
- Halaman Detail dikonstruksi secara *Factory* (Lahir ketika rute `/article` dibuka, musnah ketika di-*pop*), menghemat beban RAM.
- Memanggil `isBookmarked` setiap kali memuat halaman untuk mewarnai tombol *Bookmark AppBar*.

---

## Architecture Flow Diagrams

### 1. Repository Orchestration Flow (Toggle Bookmark)
Karena tidak melibatkan `RemoteDatasource`, *Repository* merutekan instruksi `ToggleBookmarkUseCase` langsung menuju *Storage* perangkat (Memory Flash HP) melalui jembatan **`NewsLocalDatasource`** (`SharedPreferences`).

Proses *Toggle* (_Switch_ Nyala/Mati) dieksekusi menggunakan manipulasi *Array JSON* di dalam memori tanpa perlu *database* berat seperti SQLite. Berikut adalah desain algoritmanya:

```mermaid
flowchart TD
    Start([ToggleBookmarkUseCase.call]) --> Repo[NewsRepositoryImpl.toggleBookmark]
    Repo --> LocalDS[LocalDatasource.toggleBookmark]
    
    LocalDS --> GetCache[1. Tarik String JSON dari SharedPreferences]
    
    GetCache --> Decode[2. Decode JSON ke List<Article>]
    
    Decode --> CheckIndex{3. Cek: Apakah ID Artikel sudah ada di List?}
    
    CheckIndex -- "Ketemu (Indeks >= 0)" --> Remove[Hapus Artikel dari List]
    CheckIndex -- "Tidak Ketemu" --> Add[Tambahkan Artikel ke List]
    
    Remove --> Encode[4. Encode List<Article> kembali ke String JSON]
    Add --> Encode
    
    Encode --> Save[5. Timpa SharedPreferences dengan JSON Baru]
    Save --> Return([Return Sukses Mutlak])
    
    classDef storage fill:#f9f5ff,stroke:#8a2be2,stroke-width:2px;
    classDef process fill:#e2e3e5,stroke:#6c757d;
    classDef decision fill:#fff3cd,stroke:#ffc107,stroke-width:2px;
    
    class GetCache,Save storage;
    class CheckIndex decision;
    class Decode,Remove,Add,Encode process;
```
