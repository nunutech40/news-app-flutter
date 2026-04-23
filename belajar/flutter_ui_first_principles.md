# Panduan Belajar UI Flutter: Pola First Principles

Belajar UI di Flutter menggunakan pola **First Principles** berarti membuang kebiasaan menghafal *template* atau mencontek kode secara buta. Kita membongkar UI Flutter sampai ke atom-atom penyusunnya dan memahami "Hukum Fisika"-nya. Jika Anda menguasai hukum dasar ini, Anda bisa membuat desain sekompleks apa pun tanpa perlu menghafal ratusan nama Widget.

Berikut adalah kurikulum First Principles untuk menguasai UI Flutter:

## TAHAP 1: Memahami "Hukum Fisika" Layout (Box Constraints)
Ini adalah aturan absolut nomor 1 di Flutter. Lupakan warna atau tombol, pahami mantra ini:

> **"Constraints go down. Sizes go up. Parent sets position."**
> *(Batas ukuran turun ke bawah. Ukuran asli naik ke atas. Induk yang menentukan posisi).*

**Langkah Praktik:**
1. Pahami bahwa Widget Induk (Parent) memberikan "batas" (misal: *Lebar minimal 0, maksimal layar penuh*).
2. Widget Anak (Child) melihat batas itu, lalu memutuskan seberapa besar tubuhnya.
3. Setelah Anak punya ukuran pasti, Induk baru bisa meletakkannya (di tengah, di kiri, dll).
4. Cari tahu kenapa `SizedBox` itu egois (*Tight constraint*), dan `Container` itu fleksibel (*Loose constraint*).

---

## TAHAP 2: Sumbu Koordinat (X, Y, dan Z)
Flutter tidak menggunakan sistem koordinat CSS web klasik. Flutter bermain di 3 sumbu:

* **Sumbu X (Kiri-Kanan) dan Y (Atas-Bawah)**: Kuasai `Row` dan `Column`.
  * **Inti Pelajaran**: Pahami apa itu `MainAxisAlignment` (Sumbu Utama) dan `CrossAxisAlignment` (Sumbu Silang). Pahami masalah *Infinite Space* (Kenapa `Column` di dalam `Column` bisa bikin error layar kuning hitam?).
  * **Senjata Rahasia**: Kuasai `Expanded` dan `Flexible` untuk mengatur porsi ruang (seperti pembagian persentase harta warisan).

* **Sumbu Z (Depan-Belakang)**: Kuasai `Stack`.
  * **Inti Pelajaran**: Bagaimana menumpuk teks di atas gambar. Pelajari cara kerja widget `Positioned` di dalam `Stack`.

---

## TAHAP 3: Anatomis Sebuah "Benda" (Membongkar Kotak)
Alih-alih menghafal komponen rumit, pahami blok Lego paling dasar.

* **Inti Pelajaran**: Jangan anggap `Container` sebagai kotak ajaib. Secara *first principle*, `Container` sebenarnya adalah gabungan dari beberapa widget murni:
  * Ruang bernafas ke luar = `Margin`
  * Pemberi warna/bayangan/radius = `DecoratedBox` (BoxDecoration)
  * Ruang bernafas ke dalam = `Padding`
  * Ukuran absolut = `ConstrainedBox`
* Dengan memahami ini, Anda tahu bahwa membuat efek "kaca" (*Glassmorphism*) itu murni hanya manipulasi Dekorasi dan Filter warna pada sebuah kotak dasar.

---

## TAHAP 4: Komposisi Mengalahkan Warisan (*Composition over Inheritance*)
Di bahasa lain (seperti Java/Android Native), jika Anda butuh tombol merah khusus, Anda "mewarisi" (*extends*) kelas Tombol bawaan. Di Flutter, **itu diharamkan**.

* **Inti Pelajaran**: Segala sesuatu dibangun dengan menggabungkan atom.
* Anda ingin membuat Tombol Custom? Jangan cari widget `CustomButton`. Buatlah dari nol: Gabungan `GestureDetector` (agar bisa di-klik) + `Container` (untuk bentuk dan warna) + `Text` (untuk label). Ini adalah esensi kebebasan sejati di Flutter.

---

## TAHAP 5: Melampaui Dimensi Layar (Sistem Scrolling)
Layar HP itu sangat terbatas (misal tinggi cuma 800 pixel). Bagaimana kalau atom UI Anda menuntut 2000 pixel?

* **Inti Pelajaran**: Memahami mesin *Scroll* (Viewport).
* Pahami `SingleChildScrollView` (Bungkus layar statis agar bisa digeser).
* Pahami mesin pembuat performa 60FPS: `ListView.builder`. Mengapa ia sangat cepat? Karena secara *first principle*, ia hanya menciptakan objek yang **sedang dilihat oleh mata pengguna**, yang tidak terlihat di layar akan dihancurkan sementara.

---

## TAHAP 6: Memasukkan Dimensi Waktu (State & Animasi Dasar)
UI yang Anda buat di atas semuanya "Mati" (Stateless). UI tidak bereaksi kalau disentuh.

* **Inti Pelajaran**: Kuasai `StatefulWidget`. Pahami bahwa layar itu bisa berevolusi seiring berjalannya waktu.
* Belajar mantra `setState(() {})`: Cara memberi tahu mesin Flutter, *"Hei, tolong hancurkan lukisan layar yang lama, dan lukis ulang layar baru pakai data yang barusan aku ubah."*

---

### Saran Cara Mulai Belajar:
Jangan langsung mencoba mendesain aplikasi e-commerce raksasa. Mulailah dari satu *file* kosong `main.dart`, buang semua kode bawaan, pasang `Container` warna merah di tengah layar. Lalu pelan-pelan bungkus dia dengan `Row`, berikan `Padding`, bungkus dengan `GestureDetector`, dan amati secara langsung bagaimana hukum fisika layar bereaksi terhadap setiap perubahan Anda!
