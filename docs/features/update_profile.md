# Update Profile Feature

## Overview
Modul Update Profile memungkinkan pengguna memperbarui informasi pribadi (nama, bio, preferensi) serta foto profil (avatar). Fitur ini memiliki tantangan teknis khusus pada pengolahan foto resolusi tinggi, di mana kita menggunakan arsitektur Isolate untuk memanipulasi _pixel_ gambar secara _Asynchronous_ tanpa membekukan (_freeze_) UI.

### 1. State Management (ProfileCubit)
- Menggunakan `ProfileCubit` yang bersifat _ephemeral_ (sementara), dibuat ketika `EditProfileBottomSheet` dibuka, dan dihancurkan ketika ditutup.
- Setelah sukses menyimpan data via API, Cubit ini mengirimkan event ke _Global State_ (`AuthBloc`) agar _Source of Truth_ (data profil di seluruh aplikasi) ter-update secara _real-time_.

### 2. High-Resolution Image Processing (Isolate via ImageProcessorHelper)
Pemrosesan gambar resolusi tinggi diimplementasikan menggunakan arsitektur berlapis sesuai prinsip _Clean Architecture_:

- **UI Layer** (`EditProfileBottomSheet`): Bersifat "bodoh" (_Dumb UI_). Hanya memanggil `ImageProcessorHelper.compressAndCropSquare()` dan menerima hasilnya. Tidak tahu cara kerja kompresi sama sekali.
- **Core Utility Layer** (`lib/core/utils/image_processor.dart`): Satu-satunya kelas yang bertanggung jawab atas manipulasi pixel. Mengandung:
  - `_ImageProcessParams`: DTO (Data Transfer Object) untuk membungkus konfigurasi (path, targetSize, quality) menjadi satu argumen tunggal yang bisa dikirim ke `compute()`.
  - `_processImageInIsolate()`: Fungsi _Top-Level_ (di luar class) yang dijalankan Worker Isolate. Wajib _Top-Level_ karena `compute()` hanya bisa menjalankan fungsi yang tidak terikat ke instance manapun.
  - `ImageProcessorHelper.compressAndCropSquare()`: Static method yang menjadi pintu masuk publik bagi seluruh fitur lain di aplikasi.

Pemisahan ini memastikan:
1. **Reusability**: Fitur lain (misal: upload foto artikel) bisa langsung pakai `ImageProcessorHelper` yang sama.
2. **Testability**: Logika kompresi bisa di-_unit test_ secara independen tanpa Widget.
3. **Single Responsibility**: UI hanya tahu tampilan. Core hanya tahu algoritma.

---

## Technology Stack

| Teknologi | Package / API | Versi | Peran dalam Fitur |
|---|---|---|---|
| **Image Picker** | `image_picker` | ^1.1.2 | Membuka galeri HP dan mengambil path file gambar yang dipilih user. Sengaja tanpa batasan `maxWidth` agar mengambil resolusi penuh. |
| **Image Processing** | `image` (pub.dev) | ^4.3.0 | Pure-Dart library untuk manipulasi pixel: decode JPEG/PNG, crop persegi (`copyResizeCropSquare`), dan encode ulang ke JPEG dengan quality tertentu. Berjalan di atas CPU (Software), bukan GPU/Hardware. |
| **Isolate / Concurrency** | `flutter/foundation.dart` → `compute()` | Built-in Flutter | Fungsi bawaan Flutter yang melempar sebuah fungsi Top-Level ke Worker Isolate (Core CPU terpisah), sehingga Main Thread (UI) tidak pernah freeze selama pemrosesan gambar berjalan. |
| **Data Transfer Object** | Dart (`class`) | Built-in Dart | `_ImageProcessParams` — class DTO untuk membungkus multi-parameter menjadi satu argumen tunggal. Wajib karena `compute()` hanya menerima satu parameter. |
| **State Management (Local)** | `flutter_bloc` → `Cubit` | ^9.1.0 | `ProfileCubit` mengelola state UI ephemeral: loading, sukses, dan gagal saat request update profil ke API. |
| **State Management (Global)** | `flutter_bloc` → `BLoC` | ^9.1.0 | `AuthBloc` sebagai Global Singleton. Menerima event `AuthUserUpdated` dari UI setelah profil sukses diperbarui, sehingga seluruh aplikasi ikut ter-update. |
| **Dependency Injection** | `get_it` | ^8.0.3 | `ProfileCubit` diinstansiasi via `sl<ProfileCubit>()` di dalam `BlocProvider` pada saat BottomSheet dibuka. |
| **Network (Upload)** | `dio` | ^5.7.0 | Multipart POST request untuk mengupload file gambar hasil kompresi (`_processed.jpg`) beserta data form profil ke server. |
| **File System** | `dart:io` → `File` | Built-in Dart | Membaca byte mentah file asli (`readAsBytes()`) dan menulis hasil kompresi ke file baru (`writeAsBytes()`). Digunakan di dalam Worker Isolate. |
| **Cached Image Display** | `cached_network_image` | ^3.4.1 | Menampilkan avatar profil dari URL (CDN server) dengan caching otomatis, sebagai fallback saat belum ada file lokal yang dipilih. |



## Architecture Sequence Diagrams

### 1. High-Resolution Image Processing Flow (via ImageProcessorHelper + Isolate)
Diagram ini menjelaskan bagaimana UI mendelegasikan pemrosesan gambar ke `ImageProcessorHelper` (Core Utility), yang kemudian menjalankan tugasnya di Worker Isolate.

```mermaid
sequenceDiagram
    participant User
    participant UI as EditProfileBottomSheet
    participant Helper as ImageProcessorHelper (core/utils)
    participant Worker as Worker Isolate (_processImageInIsolate)
    participant Disk as Storage/File

    User->>UI: Klik icon kamera (Pick Image)
    UI->>UI: Buka Galeri (ImagePicker, tanpa batasan ukuran)
    UI-->>UI: File Gambar Asli (Bisa 10MB+)
    
    UI->>UI: setState(_isProcessingImage = true) - Munculkan Spinner
    UI->>Helper: compressAndCropSquare(originalPath: filePath)
    
    Note over Helper,Worker: Helper membungkus params ke _ImageProcessParams DTO,<br/>lalu memanggil compute() sehingga Worker Isolate lahir.
    
    Helper->>Worker: compute(_processImageInIsolate, params)
    
    Note over UI,Worker: Main Thread bebas mengurus UI (60 FPS)<br/>sementara Worker bekerja keras di Core CPU terpisah.

    Worker->>Disk: readAsBytes() - Baca byte gambar mentah
    Disk-->>Worker: Uint8List (raw bytes)
    Worker->>Worker: img.decodeImage() - Decode ke pixel (CPU Berat)
    Worker->>Worker: img.copyResizeCropSquare(size: 500) - Crop Square
    Worker->>Worker: img.encodeJpg(quality: 80) - Kompres JPEG
    Worker->>Disk: writeAsBytes() - Simpan ke _processed.jpg
    Disk-->>Worker: Path file baru
    
    Worker-->>Helper: Return path (_processed.jpg) atau null jika error
    Helper-->>UI: Return processedPath
    
    UI->>UI: setState(_isProcessingImage = false)
    UI->>UI: Fallback - gunakan processedPath ?? originalPath
    UI->>UI: Render ImageProvider - Tampilkan Avatar Baru
```

### 2. Profile Update & Global State Synchronization Flow
Diagram ini menggambarkan siklus pengiriman data gambar + form ke server, dan bagaimana suksesnya _update_ tersebut disinkronkan ke `AuthBloc` global.

```mermaid
sequenceDiagram
    participant UI as EditProfileBottomSheet
    participant Cubit as ProfileCubit
    participant Repo as UserRepository
    participant API as ApiClient
    participant Auth as Global AuthBloc

    UI->>Cubit: saveProfile(name, file_processed, ...)
    Cubit->>UI: emit(Loading)
    
    Cubit->>Repo: updateProfile(data, file)
    Repo->>API: Multipart POST /user/profile
    
    alt Sukses
        API-->>Repo: 200 OK + Updated User JSON
        Repo-->>Cubit: Updated User Entity
        Cubit->>UI: emit(Success(updatedUser))
        
        Note over UI,Auth: UI memicu sinkronisasi Global
        UI->>Auth: add(AuthUserUpdated(updatedUser))
        Auth-->>AllApps: UI di seluruh aplikasi berubah!
        UI->>UI: Tutup BottomSheet
    else Gagal
        API-->>Repo: 400/500 Error
        Repo-->>Cubit: Failure Message
        Cubit->>UI: emit(Failure)
        UI->>UI: Munculkan SnackBar Error
    end
```

---

## Flowchart: Image Picker & Fallback Logic

```mermaid
flowchart TD
    Start([User Klik Pick Image]) --> PickGallery[Buka Galeri HP]
    
    PickGallery --> HasFile{File Dipilih?}
    HasFile -- "Tidak" --> End([Batal / Tutup])
    HasFile -- "Ya - Pilih Foto 20MB" --> ShowLoading[Munculkan Spinner di Avatar]
    
    ShowLoading --> CallHelper["Panggil ImageProcessorHelper.compressAndCropSquare()"]
    CallHelper --> RunIsolate["compute() launches Worker Isolate _processImageInIsolate()"]
    RunIsolate --> IsolateProcess["Decode - Crop Square - Encode JPG - Simpan _processed.jpg"]
    
    IsolateProcess --> IsSuccess{Berhasil?}
    
    IsSuccess -- "Ya" --> UseCompressed["Gunakan Path _processed.jpg"]
    IsSuccess -- "Gagal/Error null" --> UseOriginal[Gunakan Path File Asli - Fallback]
    
    UseCompressed --> HideLoading
    UseOriginal --> HideLoading
    
    HideLoading[Matikan Spinner] --> RenderUI[Render ImageProvider di UI]
    RenderUI --> End
    
    classDef helper fill:#bbdefb,stroke:#1976d2,stroke-width:2px;
    classDef isolate fill:#e1bee7,stroke:#8e24aa,stroke-width:2px;
    classDef success fill:#d4edda,stroke:#28a745,stroke-width:2px;
    classDef fallback fill:#fff3cd,stroke:#ffc107,stroke-width:2px;
    
    class CallHelper helper;
    class RunIsolate,IsolateProcess isolate;
    class UseCompressed success;
    class UseOriginal fallback;
```
