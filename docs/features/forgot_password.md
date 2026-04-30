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

**Algoritma iOS Autofill:**
1. **Sinyal App:** Flutter (lewat Pinput) memanggil properti `autofillHints: [AutofillHints.oneTimeCode]`. Ini di-*compile* menjadi `UITextContentType.oneTimeCode` di Swift.
2. **OS Mendengarkan:** Aplikasi hanya *"membuka mulut"* dan menunggu.
3. **SMS Masuk:** *CoreTelephony* (Sistem dasar iOS) menerima SMS dari Firebase. Mesin *Machine Learning* iOS memindai kata kunci seperti *"code"*, *"kode"*, atau *"OTP"*.
4. **Isolasi Keyboard:** OS **tidak** memberikan SMS ke aplikasi. Sebaliknya, OS secara aman memberikan 6 digit angka tersebut ke **Keyboard (QuickType)**.
5. **User Consent:** Keyboard menampilkan tulisan *“From Messages: 123456”*.
6. **Eksekusi:** JIKA user memencet (tap) teks tersebut, barulah Keyboard "menembakkan" angka 123456 ke dalam Pinput layaknya orang mengetik dengan kecepatan kilat.

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
