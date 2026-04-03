# News & Explore Features

## Overview
Modul News dan Explore adalah jantung dari penemuan konten dalam aplikasi ini. 

### 1. News Tab (Dashboard)
News tab bertugas menampilkan berita dengan kombinasi berbagai Cubit:
- `CategoryCubit`: Mengatur filter kategori
- `TrendingCubit`: Menampilkan carousel trending news
- `NewsFeedCubit`: Menampilkan list berita utama dengan *Load More*

### 2. Explore Tab
Explore tab dirancang sebagai aggregator asinkron paralel. Tidak menggunakan Repository khusus, melainkan memakai ulang `GetNewsFeedUseCase`.
- Diatur oleh single orchestrator `ExploreCubit`.
- Memanggil 3 kategori berita berbeda (Tech, Business, Sports) secara bersamaan.
- UI menampilkan efek *Pop-In* dinamis berdasarkan rekayasa _delay_ simulasi asinkronus jaringan.
