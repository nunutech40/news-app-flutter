# Update Profile Feature

## Overview
Modul Update Profile memungkinkan pengguna memperbarui informasi pribadi (nama, bio, preferensi) serta foto profil (avatar). Fitur ini memiliki tantangan teknis khusus pada pengolahan foto resolusi tinggi, di mana kita menggunakan arsitektur Isolate untuk memanipulasi _pixel_ gambar secara _Asynchronous_ tanpa membekukan (_freeze_) UI.

### 1. State Management (ProfileCubit)
- Menggunakan `ProfileCubit` yang bersifat _ephemeral_ (sementara), dibuat ketika `EditProfileBottomSheet` dibuka, dan dihancurkan ketika ditutup.
- Setelah sukses menyimpan data via API, Cubit ini mengirimkan event ke _Global State_ (`AuthBloc`) agar _Source of Truth_ (data profil di seluruuh aplikasi) ter-update secara _real-time_.

### 2. High-Resolution Image Processing (Isolate)
- Kita secara sengaja menghapus batasan `maxWidth` dan `imageQuality` pada `ImagePicker` agar pengguna dapat memilih foto beresolusi penuh.
- Proses kompresi dan _cropping_ (pemotongan persegi) sangat berat bagi CPU. Oleh karena itu, tugas ini dilempar ke luar dari _Main Thread_ menggunakan fungsi `compute()`, sehingga menciptakan _Isolate_ independen.
- Hal ini menjamin animasi loading UI tetap berjalan mulus di 60 FPS tanpa patah-patah (*Jank*).

---

## Architecture Sequence Diagrams

### 1. High-Resolution Image Processing Flow (Isolate)
Diagram ini menjelaskan bagaimana proses pemindahan kerja CPU dari UI Thread ke Isolate ketika pengguna memilih file foto yang besar.

```mermaid
sequenceDiagram
    participant User
    participant UI as EditProfileBottomSheet
    participant MainThread as Main Isolate (UI)
    participant Worker as Worker Isolate (compute)
    participant Disk as Storage/File

    User->>UI: Klik icon kamera (Pick Image)
    UI->>MainThread: Buka Galeri
    MainThread-->>UI: File Gambar Asli (Bisa 10MB+)
    
    UI->>MainThread: Munculkan Loading Spinner (setState)
    MainThread->>Worker: compute(_compressImageInIsolate, filePath)
    
    Note over MainThread,Worker: Main Thread bebas mengurus UI (60 FPS)<br/>sementara Worker bekerja keras.
    
    Worker->>Disk: Baca byte gambar mentah
    Disk-->>Worker: Uint8List
    Worker->>Worker: Decode image (Heavy CPU)
    Worker->>Worker: Crop Square (500x500)
    Worker->>Worker: Encode JPG (80% Quality)
    Worker->>Disk: Simpan file hasil compress
    Disk-->>Worker: Path file baru (_compressed)
    
    Worker-->>MainThread: Return compressed path
    MainThread->>UI: Sembunyikan Spinner, Tampilkan Avatar Baru
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

    UI->>Cubit: saveProfile(name, file_compressed, ...)
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
    HasFile -- "Ya (Pilih Foto 20MB)" --> ShowLoading[Munculkan Spinner di Avatar]
    
    ShowLoading --> RunIsolate[Jalankan compute(Isolate)]
    RunIsolate --> IsolateProcess[Decode -> Crop -> Encode]
    
    IsolateProcess --> IsSuccess{Berhasil Kompres?}
    
    IsSuccess -- "Ya" --> UseCompressed[Gunakan Path '_compressed.jpg']
    IsSuccess -- "Gagal/Error" --> UseOriginal[Gunakan Path File Asli (Fallback)]
    
    UseCompressed --> HideLoading
    UseOriginal --> HideLoading
    
    HideLoading[Matikan Spinner] --> RenderUI[Render ImageProvider di UI]
    RenderUI --> End
    
    classDef isolate fill:#e1bee7,stroke:#8e24aa,stroke-width:2px;
    classDef success fill:#d4edda,stroke:#28a745,stroke-width:2px;
    classDef fallback fill:#fff3cd,stroke:#ffc107,stroke-width:2px;
    
    class RunIsolate,IsolateProcess isolate;
    class UseCompressed success;
    class UseOriginal fallback;
```
