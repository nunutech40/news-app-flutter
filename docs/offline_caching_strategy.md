# Offline-First & Caching Strategy (News Feed)

Dokumen ini menjelaskan strategi *Graceful Degradation* untuk fitur News Feed sehingga aplikasi tetap bisa menampilkan data dan tidak kosong melompong saat perangkat pengguna offline atau jaringan bermasalah.

## 1. Konsep Utama
Alih-alih menyimpan seluruh database berita (yang akan memakan banyak Storage memori pengguna), aplikasi **hanya menyimpan (cache) halaman pertama (Page 1) dari feed berita utama (Kategori 'All')**. 

*   **Target Penyimpanan**: `SharedPreferences` (dalam bentuk JSON Text / String).
*   **Triggers**:
    *   **Write**: Saat HTTP response sukses dari endpoint `getFeed(page: 1, category: null)`.
    *   **Read**: Saat `ApiClient` melempar `NetworkException` dalam upaya memuat endpoint `getFeed(page: 1, category: null)`.

## 2. Alur Eksekusi (Orchestration)
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

## 3. Komponen yang Terlibat

### A. `NewsLocalDatasource` (Baru)
Antarmuka baru yang berinteraksi dengan `SharedPreferences`:
```dart
abstract class NewsLocalDatasource {
  Future<void> cacheNewsFeed(Map<String, dynamic> rawJson);
  Future<Map<String, dynamic>?> getCachedNewsFeed();
}
```
*Gunakan `jsonEncode` untuk menyimpan dan `jsonDecode` saat mengambil data.*

### B. `NewsRepositoryImpl` (Modifikasi)
Repository menyuntikkan Local Datasource dan mencegat `NetworkException` khusus untuk pencarian `page == 1 && category == null`.

## 4. Keuntungan Pendekatan Ini
1. **Performa Tinggi**: Ukuran string JSON 1 halaman berita (< 200KB) sangat kecil untuk diurai (parse).
2. **Efisiensi Penyimpanan**: User tidak dibebani ukuran app membengkak seiring waktu karena data selalu ditimpa (overwrite).
3. **User Experience**: Layar tidak pernah blank saat pertama buka app sambil masuk ke dalam lift bus train atau daerah susah sinyal.
