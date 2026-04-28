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
| **Local Notifications** | `flutter_local_notifications` | ^17.0.0+ | Memberikan notifikasi sistem (Heads-up) ketika profil berhasil diperbarui, dieksekusi melalui pemanggilan Native API (Android Channels / iOS Permissions). |



## Architecture Sequence Diagrams

### 1. High-Resolution Image Processing Flow (via ImageProcessorHelper + Isolate)
Diagram ini menjelaskan bagaimana UI mendelegasikan pemrosesan gambar ke `ImageProcessorHelper` (Core Utility), yang kemudian menjalankan tugasnya di Worker Isolate.

```mermaid
sequenceDiagram
    participant User
    participant UI as "UI: EditProfileBottomSheet"
    participant Helper as "core/utils: ImageProcessorHelper"
    participant Worker as "dart:isolate via compute()"
    participant Disk as "dart:io File"

    User->>UI: Tap ikon kamera
    UI->>UI: image_picker.pickImage()
    UI-->>UI: XFile path (resolusi penuh)

    UI->>UI: setState isProcessingImage=true
    Note over UI: flutter/material.dart setState
    UI->>Helper: compressAndCropSquare(path)
    Note over Helper: Bungkus ke _ImageProcessParams DTO

    Helper->>Worker: compute(_processImageInIsolate, params)
    Note over Worker: flutter/foundation.dart compute()
    Note over UI,Worker: Main Thread tetap 60 FPS

    Worker->>Disk: File.readAsBytes()
    Disk-->>Worker: Uint8List raw bytes
    Worker->>Worker: image.decodeImage()
    Worker->>Worker: image.copyResizeCropSquare(500)
    Worker->>Worker: image.encodeJpg(quality:80)
    Worker->>Disk: File.writeAsBytes()
    Disk-->>Worker: String path _processed.jpg

    Worker-->>Helper: return String? path
    Helper-->>UI: return processedPath

    UI->>UI: setState isProcessingImage=false
    UI->>UI: File(processedPath ?? originalPath)
    UI->>UI: Render FileImage di CircleAvatar
```

### 2. Profile Update & Global State Synchronization Flow

```mermaid
sequenceDiagram
    participant UI as "UI: EditProfileBottomSheet"
    participant Cubit as "flutter_bloc: ProfileCubit"
    participant Repo as "Domain: UserRepository"
    participant API as "dio: ApiClient (Multipart)"
    participant Auth as "flutter_bloc: AuthBloc (Global)"
    participant Notif as "core/services: NotificationService"
    participant OS as "Native OS (Android/iOS)"

    UI->>Cubit: saveProfile(name, bio, file)
    Cubit->>UI: emit ProfileLoading
    Note over UI: CircularProgressIndicator tampil

    Cubit->>Repo: updateProfile(params, File)
    Repo->>API: dio POST /user/profile (FormData)
    Note over API: Header Bearer token otomatis via Interceptor

    alt HTTP 200 OK
        API-->>Repo: JSON updatedUser
        Repo-->>Cubit: Right(UserEntity)
        Cubit->>UI: emit ProfileSuccess(updatedUser)
        UI->>Auth: add AuthUserUpdated(updatedUser)
        Note over Auth: get_it sl<AuthBloc> Singleton
        Auth-->>UI: emit AuthAuthenticated (seluruh app update)
        UI->>UI: Navigator.pop + SnackBar sukses
        UI->>Notif: NotificationService.showNotification()
        Notif->>OS: Plugin memanggil Native Code
        OS-->>User: Muncul Notifikasi Heads-Up "Update Berhasil"
    else HTTP 4xx/5xx
        API-->>Repo: DioException
        Repo-->>Cubit: Left(Failure)
        Cubit->>UI: emit ProfileFailure(message)
        UI->>UI: SnackBar error merah
    end
```

---

## Flowchart: Image Processing Flow

### Overview

```mermaid
flowchart LR
    A([Tap Kamera]) --> B[Main Thread]
    B -- "compute()" --> C([Worker Isolate])
    C -- "path" --> D[Main Thread]
    D --> E([Selesai])

    style B fill:#c8e6c9,stroke:#388e3c,color:#000
    style C fill:#e1bee7,stroke:#8e24aa,color:#000
    style D fill:#c8e6c9,stroke:#388e3c,color:#000
```

### Detail

```mermaid
flowchart TD
    A([Tap Kamera]) --> B[PickImage]
    B --> C{Dipilih?}
    C -- Tidak --> Z([Batal])
    C -- Ya --> D[Spinner ON]
    D --> E([Isolate])
    E --> F{OK?}
    F -- Ya --> G[Processed]
    F -- Error --> H[Fallback]
    G --> I[Render]
    H --> I
    I --> Z2([Selesai])

    classDef ui fill:#c8e6c9,stroke:#388e3c,color:#000
    classDef isolate fill:#e1bee7,stroke:#8e24aa,color:#000
    classDef success fill:#d4edda,stroke:#28a745,color:#000
    classDef fallback fill:#fff3cd,stroke:#f57c00,color:#000

    class B,D,I ui
    class E isolate
    class G success
    class H fallback
```

**Keterangan node:**

| Node | Teknologi | Keterangan |
|---|---|---|
| **PickImage** | `image_picker` | Buka galeri, ambil file resolusi penuh |
| **Spinner ON** | `flutter/material.dart setState` | `_isProcessingImage = true` |
| **Isolate** | `flutter/foundation.dart compute()` | `ImageProcessorHelper.compressAndCropSquare()` → decode → crop 500px → encode JPG 80% → `dart:io writeAsBytes` |
| **Processed** | `dart:io File` | Gunakan `_processed.jpg` |
| **Fallback** | `dart:io File` | Gunakan file asli jika Isolate error |
| **Render** | `flutter/widgets.dart FileImage` | Tampil di `CircleAvatar` |

---

## Architecture Sequence Diagrams: Local Notification

### 3. Local Notification Initialization & Trigger Flow

Diagram ini menjelaskan bagaimana proses pendaftaran birokrasi _Native_ (Channel & Permission) dilakukan di awal aplikasi, lalu dipicu oleh UI saat profil berhasil diubah.

```mermaid
sequenceDiagram
    participant Main as "main.dart"
    participant Notif as "NotificationService"
    participant Plugin as "flutter_local_notifications"
    participant OS as "Native OS"
    participant UI as "EditProfileBottomSheet"

    Note over Main,OS: Tahap 1: Inisialisasi (App Start)
    Main->>Notif: NotificationService.initialize()
    Notif->>Plugin: initialize(InitializationSettings)
    Plugin->>OS: Daftarkan pengaturan awal (Icon dll)
    Notif->>Plugin: requestNotificationsPermission()
    Plugin->>OS: OS mengecek izin / memunculkan dialog (Android 13+ / iOS)
    OS-->>Plugin: User Grant Permission
    
    Note over UI,OS: Tahap 2: Triggering (Profile Saved)
    UI->>UI: State == ProfileSuccess
    UI->>Notif: showNotification(title, body)
    Notif->>Plugin: show(NotificationDetails)
    Note over Plugin: Membawa "KTP" AndroidNotificationDetails
    Plugin->>OS: Minta OS memunculkan Heads-up
    OS-->>User: Pop-up Notifikasi Muncul!
```

---

## Flowchart: Local Notification Algorithm

### Overview Logic
Flowchart ini menggambarkan logika kondisional yang terjadi di balik layar saat menginisialisasi dan menembakkan notifikasi lokal, termasuk penanganan izin OS.

```mermaid
flowchart TD
    A([Aplikasi Dibuka]) --> B[Inisialisasi Plugin]
    B --> C{Cek Platform OS}
    
    C -- "Android < 13" --> D[Siapkan Channel (KTP)]
    C -- "Android >= 13" --> E{Sudah Diberi Izin?}
    C -- "iOS" --> F{Sudah Diberi Izin?}
    
    E -- Belum --> G[Minta Izin POST_NOTIFICATIONS]
    F -- Belum --> H[Minta Izin Alert/Badge/Sound]
    
    G --> I{User Mengizinkan?}
    H --> I
    
    E -- Sudah --> D
    F -- Sudah --> D
    I -- Ya --> D
    I -- Tidak --> Z([Notifikasi Mati Secara Silent])
    
    D --> J([Standby Menunggu Aksi])
    J --> K[User Menyimpan Profil]
    K --> L{Status Update?}
    L -- Sukses --> M[Panggil showNotification]
    L -- Gagal --> J
    
    M --> N{Status Channel Settings?}
    N -- Dimatikan User --> Z
    N -- Menyala --> O[OS Munculkan Heads-Up!]
    
    classDef init fill:#e1bee7,stroke:#8e24aa,color:#000
    classDef check fill:#fff3cd,stroke:#f57c00,color:#000
    classDef action fill:#c8e6c9,stroke:#388e3c,color:#000
    classDef stop fill:#ffcdd2,stroke:#d32f2f,color:#000
    
    class B,D,M init
    class C,E,F,I,L,N check
    class O action
    class Z stop
```
