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

// Auth - Presentation
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ==================== External ====================
  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ==================== Datasources ====================
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
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenProvider: sl()),
  );

  // Remote datasource uses ApiClient
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(apiClient: sl()),
  );

  // ==================== Repository ====================
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: sl(),
      localDatasource: sl(),
    ),
  );

  // ==================== Use Cases ====================
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // ==================== BLoC ====================
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      getProfileUseCase: sl(),
      logoutUseCase: sl(),
      authRepository: sl(),
    ),
  );
}
