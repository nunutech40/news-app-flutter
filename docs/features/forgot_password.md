# Arsitektur Forgot Password & Mekanisme Autofill OTP

Dokumen ini menjelaskan alur kerja dari fitur Lupa Password (Forgot Password) beserta algoritma *under-the-hood* bagaimana **Pinput** menangani Autofill SMS OTP di platform iOS dan Android.

---

## 1. Alur TDD (Test-Driven Development) Forgot Password
Dalam aplikasi ini, fitur Forgot Password dipecah menjadi beberapa tahapan *Clean Architecture* yang ketat:

1. **Request Reset:** User memasukkan nomor HP/Email. Aplikasi meminta Firebase untuk mengirimkan SMS berisi kode OTP.
2. **OTP Verification:** User memasukkan 6 digit kode OTP.
3. **Token Exchange:** Setelah OTP valid, Firebase mengembalikan `FirebaseIDToken`.
4. **Backend Reset:** Aplikasi mengirimkan `FirebaseIDToken` + `Password Baru` ke backend utama (Go server).
5. **Security Cleanup:** Backend memverifikasi token Firebase, mengganti password di database lokal, dan *mencabut (revoke)* seluruh token sesi lama agar user harus login ulang.

---

## 2. Pinput: Algoritma & Logika Autofill OTP

Package `pinput` bukanlah aplikasi pembaca SMS ajaib. Ia adalah *UI Wrapper* cerdas yang menjembatani komunikasi antara kolom teks Flutter (TextField) dengan **Framework Autofill Bawaan OS (Sistem Operasi)**.

### A. Mekanisme di iOS (Apple Privacy Model)
Apple sangat mengutamakan privasi. Tidak ada aplikasi pihak ketiga di iOS (termasuk aplikasi buatan Anda) yang diizinkan untuk membaca kotak masuk SMS secara langsung (API diblokir penuh).

**Low-Level Arsitektur iOS Autofill (Menembus Native OS):**
1. **Flutter Framework (Layer Dart):** Saat kita memanggil `autofillHints: [AutofillHints.oneTimeCode]`, layer UI Flutter membungkus data ini ke dalam format JSON/Map.
2. **Platform Channels (Method Channel `flutter/textinput`):** Data JSON dikirimkan melewati *Flutter Engine* (C++) untuk menyeberang ke alam Native iOS.
3. **FlutterTextInputPlugin (Layer Objective-C iOS):** Di sisi Native, plugin menangkap pesan tersebut dan memunculkan *"Hidden Proxy"* (komponen UI kasat mata buatan Native iOS). Di sinilah eksekusi API Apple dipanggil:
   ```objective-c
   proxyTextField.textContentType = UITextContentTypeOneTimeCode;
   [proxyTextField becomeFirstResponder];
   ```
   *Fungsi `becomeFirstResponder` inilah yang secara harfiah merupakan "colekan" ke OS iOS untuk mengatakan: "Bangun! Buka Keyboard sekarang!"*
4. **UIKit & Input Method API:** UIKit melihat properti `.oneTimeCode` dan meneruskan metadata ini ke **Input Method API** (sistem kernel yang mengontrol Keyboard).
5. **NSDataDetector & CoreTelephony:** Keyboard secara rahasia membangunkan **CoreTelephony** (pembaca sinyal SMS background) dan **NSDataDetector** (Mesin *Machine Learning NLP* Apple). Mesin ML mencari pola 6 angka di sekitar kata "code" atau "OTP" pada SMS terbaru.
6. **Eksekusi Akhir:** Angka yang diculik mesin ML dikirim ke layar Keyboard menjadi tombol saran *“From Messages: 123456”*. JIKA user menyetujui dan memencet tombol tersebut, angka tersebut akan ditembakkan kembali melintasi Method Channel, menembus Engine, dan akhirnya mendarat di widget Pinput Flutter.

### B. Mekanisme di Android
Android memiliki pendekatan yang lebih fleksibel dan terbagi menjadi dua jalur teknologi:

#### Jalur 1: Android Autofill Framework (Mirip iOS)
Jika Anda hanya memakai `autofillHints` bawaan, Android akan merubahnya menjadi konstan `View.AUTOFILL_HINT_SMS_OTP`.
- Cara kerjanya persis seperti iOS. Google Keyboard (Gboard) akan membaca SMS, lalu memunculkan kodenya di atas deretan huruf keyboard. User harus melakukan tap manual.

#### Jalur 2: SMS Retriever API (Sistem Sedot Background)
Ini adalah fitur eksklusif Android melalui **Google Play Services** (membutuhkan package pendamping seperti `smart_auth`).
Ini memungkinkan aplikasi menyedot kode secara *seketika* tanpa user perlu menyentuh keyboard sama sekali.

**Algoritma SMS Retriever:**
1. **Start Listening:** Aplikasi memanggil OS untuk *standby* selama 5 menit menunggu SMS khusus.
2. **Syarat SMS:** Firebase mengirimkan SMS dengan format wajib yang dipatenkan Google:
   ```text
   <#> Your News App verification code is: 123456
   FA+9qCX9VSu
   ```
   *(Penjelasan: `<#>` adalah prefix API, dan `FA+9qCX9VSu` adalah 11-digit App Signature Hash unik dari aplikasi Android Anda).*
3. **Bypass Langsung:** Saat SMS masuk, OS Android melihat akhiran Hash. Karena Hash-nya cocok dengan aplikasi News App, Android **mem-bypass kotak masuk SMS biasa** dan langsung *mengirimkan* isi pesan tersebut ke dalam *Background Listener* Pinput.
4. **Auto-Fill:** Pinput mengekstrak angka `123456` menggunakan *Regular Expression (Regex)* dan mengisinya ke kotak UI tanpa intervensi manusia.

---

## 3. Rangkuman Teknologi yang Terlibat
- **Flutter Framework:** `AutofillGroup` dan `AutofillHints`.
- **Package `pinput`:** UI Rendering untuk *pin box* dan penanganan *TextEditingController*.
- **Package `smart_auth`:** *Optional* (Jika ingin mengaktifkan SMS Retriever API di Android versi 4+).
- **iOS Native:** `UITextContentType.oneTimeCode` & *QuickType Keyboard Engine*.
- **Android Native:** `Autofill Framework` & `Google Play Services SMS Retriever API`.
- **Firebase Auth:** Sistem pengirim SMS yang men-*generate* OTP & App Hash otomatis ke HP tujuan.
