# 🚀 Roadmap Portofolio: Flutter Hardware & OS Specialist

Dokumen ini berisi daftar fitur yang dirancang secara khusus **bukan untuk tujuan bisnis/produk lurus**, melainkan untuk memamerkan penguasaan teknis tingkat lanjut (*Senior-Level Portfolio*) terhadap interaksi antara *Flutter* dan *Native Hardware/OS*. 

Setiap fitur direncanakan agar sejalan dengan prinsip **Clean Architecture**, membuktikan bahwa komponen *hardware* murni pun bisa dikendalikan secara elegan lewat lapisan abstraksi.

---

## 1. 🧬 Biometric Authentication (Face ID / Touch ID)
**Tujuan Portofolio:** Membuktikan kemampuan interaksi dengan *Native Security OS* dan integrasi otentikasi lokal ke dalam skema keamanan aplikasi.

*   **Ide Fitur:** **"Private Bookmarks"** atau **App Lock**. User dapat mengunci kumpulan berita yang di-bookmark, dan hanya bisa dibuka setelah validasi sidik jari atau wajah.
*   **Hardware / OS:** Sensor Sidik Jari (Fingerprint) / Face ID.
*   **Package Utama:** `local_auth`
*   **Fokus Arsitektur:** 
    *   Membungkus *package* pihak ketiga ke dalam `BiometricDatasource`.
    *   Menginjeksinya ke `AuthRepository` dan dieksekusi melalui `VerifyBiometricUseCase`.
    *   Menghindari logika pemanggilan *hardware* berserakan di UI.

## 2. 🌍 Location Services & Geocoding (GPS)
**Tujuan Portofolio:** Menguasai pengelolaan *Runtime Permissions* (izin sistem yang sering rumit) dan pengambilan kordinat secara presisi.

*   **Ide Fitur:** **"Tab Berita Lokal"**. Aplikasi mendeteksi lokasi geografis pengguna (misal: "Bandung") dan secara dinamis menarik berita lokal dari *Backend* (atau API pihak ketiga).
*   **Hardware / OS:** Modul GPS (Location Manager).
*   **Package Utama:** `geolocator` (kordinat), `geocoding` (terjemahan nama kota), `permission_handler`.
*   **Fokus Arsitektur:** 
    *   Sistem permohonan izin (Permission Request) yang anggun (tidak *crash* saat izin ditolak).
    *   Penyatuan data lokasi `LocationDatasource` dengan data jaringan `NewsRemoteDatasource`.

## 3. 🎙️ Microphone & Speaker (Speech-to-Text & TTS)
**Tujuan Portofolio:** Memamerkan keahlian mengolah *continuous data stream* (audio) dan fitur aksesibilitas (*Accessibility*).

*   **Ide Fitur:**
    1.  **Pencarian Suara (*Voice Search*):** Ikon mikrofon di bilah pencarian, mengubah suara ke teks secara *real-time*.
    2.  **Pembaca Berita (*Read Aloud*):** Mengubah teks artikel menjadi suara layaknya podcast.
*   **Hardware / OS:** Mikrofon dan Speaker / Engine Text-to-Speech bawaan OS.
*   **Package Utama:** `speech_to_text`, `flutter_tts`.
*   **Fokus Arsitektur:** 
    *   Mengatur aliran data suara *real-time* ke dalam `Cubit` (state management).
    *   Membangun animasi UI *waveform* yang reaktif terhadap volume suara (*decibel*).

## 4. 📳 Accelerometer & Gyroscope (Sensors)
**Tujuan Portofolio:** Memanipulasi arus data berkecepatan tinggi (ratusan *event* per detik) tanpa menyebabkan kebocoran memori atau lag pada UI.

*   **Ide Fitur:** **"Shake to Refresh"**. Mengocok HP untuk memperbarui *News Feed* sebagai alternatif *pull-to-refresh*.
*   **Hardware / OS:** Sensor Gerak (Accelerometer).
*   **Package Utama:** `sensors_plus`.
*   **Fokus Arsitektur:** 
    *   Penggunaan *Debouncer* dan *Throttler* di level `Bloc` untuk menahan laju *event* *hardware* yang masuk, demi mempertahankan 60 FPS pada UI.

## 5. 👻 Background Services & Push Notifications (The Ultimate Boss)
**Tujuan Portofolio:** Membuktikan pemahaman terdalam tentang *Dart Isolates* dan *Lifecycle App* (mengeksekusi kode saat UI sudah mati).

*   **Ide Fitur:** **"Morning Briefing Alert"**. Aplikasi secara diam-diam terbangun di latar belakang setiap pukul 07:00 pagi, menarik berita *trending* dari *Backend*, dan memunculkan *Local Notification*.
*   **Hardware / OS:** OS Background Scheduler (Android WorkManager / iOS Background Fetch), Notification Tray.
*   **Package Utama:** `workmanager`, `flutter_local_notifications`.
*   **Fokus Arsitektur:** 
    *   Menginjeksi dependensi (GetIt) di lingkungan *Isolate* (lingkungan latar belakang yang terisolasi dari memori utama aplikasi).
    *   Mengirim *Push Notification* secara lokal berdasarkan data hasil *fetch* di *background*.

---
*Dokumen ini merupakan panduan evaluasi diri (Self-Evaluation Roadmap) yang akan dikerjakan secara bertahap demi menembus kualifikasi level "Senior Mobile Engineer".*
