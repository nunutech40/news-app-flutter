import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/core/router/app_router.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/injection_container.dart' as di;
import 'package:news_app/injection_container.dart';

// =============================================================================
// PANDUAN KONFIGURASI main.dart (PRODUCTION-READY)
// =============================================================================
// File `main.dart` adalah titik masuk aplikasi. Semua konfigurasi global yang 
// HARUS AKTIF sebelum UI ditampilkan, harus ditulis di sini.
//
// CHECKLIST KONFIGURASI STANDAR:
// 1. WidgetsFlutterBinding    → Wajib jika ada async call sebelum runApp()
// 2. Orientasi Layar          → Kunci portrait-only untuk app mobile
// 3. Status Bar Style         → Atur warna status bar agar konsisten dengan tema
// 4. Dependency Injection     → Inisialisasi GetIt (service locator)
// 5. Global Error Handler     → Tangkap crash Flutter & Dart agar tidak silent
// 6. BLoC Observer            → Logging transisi state di mode debug
// 7. runApp                   → Jalankan widget utama
//
// OPSIONAL (tambahkan sesuai kebutuhan):
// - Firebase.initializeApp()  → Jika pakai Firebase (Analytics, Crashlytics)
// - dotenv.load()             → Jika pakai file .env untuk konfigurasi
// - Hive.initFlutter()        → Jika pakai Hive sebagai local DB
// - TimeZone initialization   → Jika ada fitur scheduling/notifikasi
// =============================================================================

void main() async {
  // ── 1. BINDING ──────────────────────────────────────────────────────────
  // Wajib dipanggil PERTAMA jika ada operasi async sebelum runApp().
  // Tanpa ini, pemanggilan SharedPreferences.getInstance() dll akan crash.
  WidgetsFlutterBinding.ensureInitialized();

  // ── 2. ORIENTASI LAYAR ──────────────────────────────────────────────────
  // Kunci orientasi ke portrait saja. Kebanyakan app berita/sosmed
  // tidak memerlukan landscape mode. Hapus ini jika butuh landscape.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── 3. STATUS BAR STYLE ─────────────────────────────────────────────────
  // Atur tampilan status bar (jam, sinyal, baterai) agar sesuai tema gelap.
  // - statusBarColor: transparan agar menyatu dengan background app.
  // - statusBarIconBrightness: light (ikon putih) untuk tema gelap.
  SystemChrome.setSystemUIOverlayStyle(const SystemUIOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android
    statusBarBrightness: Brightness.dark,      // iOS
  ));

  // ── 4. DEPENDENCY INJECTION ─────────────────────────────────────────────
  // Inisialisasi semua service: Storage, ApiClient, DataSource, Repository,
  // UseCase, dan BLoC. Lihat injection_container.dart untuk detail.
  await di.initDependencies();

  // ── 5. BLOC OBSERVER (DEBUG ONLY) ───────────────────────────────────────
  // Aktifkan logging otomatis setiap kali ada Event masuk atau State berubah
  // di SEMUA BLoC. Sangat berguna untuk debugging, tapi jangan aktifkan
  // di production karena membanjiri console.
  if (kDebugMode) {
    Bloc.observer = _AppBlocObserver();
  }

  // ── 6. GLOBAL ERROR HANDLER ─────────────────────────────────────────────
  // Tangkap error yang "lolos" dari try-catch (unhandled).
  // Di production, kirim ke Crashlytics/Sentry. Di debug, print ke console.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('🔴 FlutterError: ${details.exceptionAsString()}');
    }
    // TODO: Tambahkan FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  // Tangkap error async yang tidak tertangkap oleh FlutterError.onError
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('🔴 PlatformError: $error');
      debugPrint(stack.toString());
    }
    // TODO: Tambahkan FirebaseCrashlytics.instance.recordError(error, stack);
    return true; // true = error sudah ditangani, jangan crash app
  };

  // ── 7. RUN APP ──────────────────────────────────────────────────────────
  runApp(const NewsApp());
}

// =============================================================================
// BLOC OBSERVER (Alat Bantu Debug)
// =============================================================================
// Mencetak log setiap kali:
// - Event baru masuk ke BLoC (onCreate, onEvent)
// - State berubah (onTransition)
// - Error terjadi di dalam BLoC (onError)
//
// Output contoh di console:
//   🟢 Event: AuthLoginRequested
//   🔄 Transition: AuthState(loading) → AuthState(authenticated)
// =============================================================================
class _AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('🟢 Event: ${bloc.runtimeType} → $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('🔄 Transition: ${bloc.runtimeType}');
    debugPrint('   Current: ${transition.currentState}');
    debugPrint('   Next:    ${transition.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('🔴 BlocError: ${bloc.runtimeType} → $error');
  }
}

// =============================================================================
// WIDGET UTAMA APLIKASI
// =============================================================================
class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc disediakan di level PALING ATAS agar bisa diakses oleh
    // semua halaman (Splash, Login, Register, Dashboard) tanpa perlu
    // masing-masing halaman membuat BLoC sendiri.
    return BlocProvider<AuthBloc>.value(
      value: sl<AuthBloc>(),
      child: Builder(
        builder: (context) {
          final appRouter = AppRouter(
            authBloc: context.read<AuthBloc>(),
          );

          return MaterialApp.router(
            title: 'NewsApp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
