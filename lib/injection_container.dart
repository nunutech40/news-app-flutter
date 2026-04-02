import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'package:news_app/core/network/api_client.dart';
import 'package:news_app/core/network/token_provider.dart';

// Auth - Data
import 'package:news_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:news_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:news_app/features/auth/data/repositories/auth_repository_impl.dart';

// Auth - Domain
import 'package:news_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:news_app/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/update_profile_usecase.dart';

// Auth - Presentation
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/features/auth/presentation/cubit/profile_cubit.dart';

// News - Data
import 'package:news_app/features/news/data/datasources/news_remote_datasource.dart';
import 'package:news_app/features/news/data/repositories/news_repository_impl.dart';

// News - Domain
import 'package:news_app/features/news/domain/repositories/news_repository.dart';
import 'package:news_app/features/news/domain/usecases/get_article_usecase.dart';
import 'package:news_app/features/news/domain/usecases/get_categories_usecase.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';

// News - Presentation
import 'package:news_app/features/news/presentation/cubit/category_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/news_feed_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/trending_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/search_cubit.dart';

// Global Event
import 'package:news_app/core/bloc/global_alert/global_alert_bloc.dart';

// =============================================================================
// PANDUAN PEMILIHAN TIPE REGISTRASI DI GET_IT
// =============================================================================
//
// GetIt menyediakan 3 cara utama untuk mendaftarkan dependency:
//
// 1. registerLazySingleton<T>(() => ...)
//    - Objek HANYA DIBUAT SEKALI, saat pertama kali diminta (lazy).
//    - Setelah dibuat, instance yang SAMA dipakai terus selama app hidup.
//    - COCOK UNTUK: Service/Datasource/Repository/ApiClient yang STATELESS 
//      (tidak menyimpan data sementara) dan MAHAL untuk dibuat ulang.
//    - CONTOH: ApiClient (koneksi Dio), SecureStorage, SharedPreferences.
//
// 2. registerFactory<T>(() => ...)
//    - Setiap kali diminta, GetIt membuat INSTANCE BARU (fresh).
//    - Tidak ada sharing antar pemanggil.
//    - COCOK UNTUK: BLoC/Cubit yang HARUS FRESH setiap halaman dibuka.
//      Misalnya: FormBloc untuk halaman edit profil; setiap kali user buka 
//      halaman edit, state-nya harus kosong/reset, bukan sisa data lama.
//    - CONTOH: EditProfileBloc, SearchBloc, FormCubit.
//
// 3. registerSingleton<T>(...)
//    - Mirip LazySingleton, tapi objek LANGSUNG DIBUAT saat `initDependencies()`
//      dipanggil, tanpa menunggu ada yang meminta.
//    - COCOK UNTUK: Dependency yang WAJIB SIAP sebelum app berjalan.
//    - CONTOH: Logger, Analytics, Firebase instance.
//
// KAPAN PAKAI LAZYSINGLETON vs FACTORY UNTUK BLOC?
// - LazySingleton: BLoC yang state-nya harus BERTAHAN lintas halaman.
//   Contoh: AuthBloc (status login harus diingat dari Splash → Login → Dashboard).
// - Factory: BLoC yang state-nya harus DIRESET setiap halaman dibuka.
//   Contoh: SearchNewsBloc (setiap buka halaman search, hasil pencarian harus kosong).
//
// =============================================================================

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ==================== External ====================
  // LazySingleton: Library bawaan OS yang cukup satu instance seumur app.
  // Tidak perlu dibuat ulang karena ia hanya jembatan ke native storage.
  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ==================== Datasources ====================
  // LazySingleton: DataSource bersifat STATELESS (tidak menyimpan variabel lokal).
  // Ia hanya meneruskan panggilan ke storage/API. Satu instance cukup.
  // Local first — needed by ApiClient for token injection
  sl.registerLazySingleton<AuthLocalDatasource>(
    () => AuthLocalDatasourceImpl(
      secureStorage: sl(),
      sharedPreferences: sl(),
    ),
  );

  // TokenProvider points to the same AuthLocalDatasource instance
  sl.registerLazySingleton<TokenProvider>(
    () => sl<AuthLocalDatasource>(),
  );

  // ==================== Core ====================
  // LazySingleton: ApiClient membungkus Dio yang MAHAL untuk diinisialisasi
  // (setup interceptor, timeout, base URL). Cukup satu instance untuk seluruh app.
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenProvider: sl(), globalAlertBloc: sl()),
  );

  // LazySingleton: Sama seperti LocalDatasource, ia STATELESS.
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(apiClient: sl()),
  );

  // ==================== Repository ====================
  // LazySingleton: Repository STATELESS, hanya orkestrator antar datasource.
  // Tidak ada alasan untuk membuat ulang di setiap pemanggilan.
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: sl(),
      localDatasource: sl(),
    ),
  );

  // ==================== Use Cases ====================
  // LazySingleton: UseCase STATELESS, hanya meneruskan panggilan ke Repository.
  // Sangat ringan dan tidak perlu dibuat ulang.
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // ==================== BLoC ====================
  // GlobalAlertBloc is a singleton covering the whole app to intercept Dio network errors automatically
  sl.registerLazySingleton<GlobalAlertBloc>(() => GlobalAlertBloc());

  // LazySingleton: AuthBloc SENGAJA dibuat singleton karena STATUS AUTENTIKASI
  // harus PERSISTENT (bertahan) lintas halaman.
  // Contoh: Setelah register sukses di RegisterPage, state `registrationSuccess`
  // harus masih bisa dibaca oleh LoginPage untuk menampilkan SnackBar.
  // Jika diganti Factory, state akan hilang setiap pindah halaman (BLoC baru).
  //
  // CATATAN: Untuk BLoC fitur lain (misal: SearchNewsBloc, EditProfileBloc),
  // gunakan registerFactory agar state-nya selalu fresh/reset.
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      getProfileUseCase: sl(),
      logoutUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ==================== News ====================
  // LazySingleton: Datasource & Repository stateless
  sl.registerLazySingleton<NewsRemoteDatasource>(
    () => NewsRemoteDatasourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<NewsRepository>(
    () => NewsRepositoryImpl(remoteDatasource: sl()),
  );

  // ==================== News Use Cases ====================
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetNewsFeedUseCase(sl()));
  sl.registerLazySingleton(() => GetArticleUseCase(sl()));

  // Factory: Cubits must be fresh every time dashboard is opened
  sl.registerFactory(() => CategoryCubit(sl()));
  sl.registerFactory(() => NewsFeedCubit(sl()));
  sl.registerFactory(() => TrendingCubit(sl()));
  sl.registerFactory(() => SearchCubit(sl()));
  sl.registerFactory(() => ProfileCubit(
    updateProfileUseCase: sl(),
    apiClient: sl(),
  ));
}
