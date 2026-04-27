# Roadmap Menuju Flutter Expert & Remote Job

Dokumen ini berisi daftar area kompetensi esensial untuk mencapai level "Flutter Expert" yang siap bersaing di pasar kerja remote global. Fokus utama bukan pada menghafal nama widget, melainkan pemahaman *under the hood*, arsitektur, testing, dan performa.

## Fase 1: Fundamental Dart & "Under the Hood" Flutter
Perusahaan remote menguji seberapa dalam Anda memahami Dart dan cara kerja *engine* Flutter.

1. **Konsep Dart Modern**
   - **Null Safety**: Pemahaman mendalam tentang `?`, `!`, `late`, dan `required` (kapan dan kenapa digunakan).
   - **Asynchronous Programming**: Perbedaan `Future` dan `Stream`. Memahami `async`, `await`, `yield`, dan `Completer`.
   - **Advanced OOP**: Penggunaan `mixin`, `extension methods`, `typedef`, dan `Generics` (`<T>`).
   - **Concurrency (Isolates)**: Memahami bahwa Dart adalah *single-threaded* (Event Loop). Kemampuan memindahkan tugas berat (parsing JSON) ke `Isolate` atau `compute()` agar UI tidak *freeze*.

2. **Core Flutter ("The Three Trees")**
   - **Widget Tree**: Konfigurasi statis yang mendeskripsikan UI.
   - **Element Tree**: Manajer *lifecycle* yang menjembatani Widget dan RenderObject. Memegang `BuildContext` (yang sejatinya adalah Element).
   - **RenderObject Tree**: Objek yang benar-benar melakukan kalkulasi ukuran (*layouting*) dan menggambar (*painting*) pixel di layar.
   - **Widget Lifecycle**: Menguasai siklus hidup `StatefulWidget` (`initState`, `didChangeDependencies`, `didUpdateWidget`, `dispose`).
   - **Flutter Keys**: Kapan harus menggunakan `ValueKey`, `ObjectKey`, `UniqueKey`, dan memahami "biaya mahal" penggunaan `GlobalKey`.

## Fase 2: Arsitektur & State Management (Skill Industri)
Di *real-world project*, kode UI harus sepenuhnya dipisah dari *Business Logic*.

1. **State Management Core**
   - Memahami konsep dasar `InheritedWidget`. (Semua *state management* modern pada dasarnya dibangun di atas mekanisme `InheritedWidget`).
2. **Kuasai State Management Populer**
   - **BLoC (Business Logic Component)**: Standar *enterprise*. Paham perbedaan `Cubit` dan `Bloc`, serta konsep arsitektur *Event-to-State*.
   - **Riverpod**: Standar modern komunitas Flutter (pengganti Provider).
3. **Design Pattern & Clean Code**
   - Menguasai **Clean Architecture** (Domain, Data, Presentation).
   - Mengimplementasi pattern **MVVM** atau **MVC**.
   - **Dependency Injection**: Mengelola ketergantungan *class* dengan package seperti `get_it` dan `injectable`.

## Fase 3: Performa & Testing (Pembeda Junior vs Expert)
Kualitas aplikasi yang diukur dari kecepatan respons (tidak *janky*) dan stabilitas (*crash-free*).

1. **Automated Testing (Sangat krusial untuk TDD)**
   - **Unit Testing**: Mengetes *business logic/function*. Kemampuan melakukan *Mocking* (`mockito` atau `mocktail`) untuk simulasi API eksternal.
   - **Widget Testing**: Mengetes interaksi komponen UI tanpa memutar emulator (`find.byType`, `tester.tap`).
   - **Integration Testing**: Simulasi end-to-end mengontrol aplikasi secara otomatis.
2. **Performance Optimization**
   - Mahir menggunakan **Flutter DevTools**.
   - **Performance View**: Menganalisa frame rate drop / jank.
   - **Memory View**: Menganalisa dan mengatasi *Memory Leak* (objek tidak di-`dispose`).
   - Mengoptimalkan *Rebuilds*: Ekstensif menggunakan `const` constructor, memakai `RepaintBoundary` untuk memisahkan area render berat, dan penggunaan struktur *builder* (`ListView.builder`) dengan benar.

## Fase 4: Tooling, CI/CD & Native Interoperability
Kemampuan level *Senior* untuk integrasi ekosistem.

1. **Native Interoperability**
   - **Method Channels & Event Channels**: Membangun jembatan komunikasi antara kode Flutter dengan kode *native* (Swift untuk iOS, Kotlin untuk Android).
2. **Flavoring (Environments)**
   - Melakukan setup *Flavors* di sisi *native* (Android `build.gradle` & iOS `Xcode`) untuk memisahkan environment `Development`, `Staging`, dan `Production`.
3. **CI/CD**
   - Otomatisasi pengujian dan *build* rilis menggunakan GitHub Actions, Codemagic, atau Bitrise.

## Tips Ekstra untuk Pekerjaan Remote
1. **GitHub Portofolio**: Bangun 1-2 aplikasi kompleks dengan *Clean Architecture*, TDD (*test coverage* > 80%), CI/CD otomatis, dan desain antarmuka premium.
2. **Kontribusi Open Source**: Memiliki riwayat kontribusi (PR) pada *package* populer di `pub.dev` atau core *Flutter engine*.
3. **Komunikasi**: Kemampuan menjelaskan *architectural decisions* dan kendala teknis secara jelas, baik tertulis (Slack) maupun lisan (Standup Meetings) dalam bahasa Inggris.
