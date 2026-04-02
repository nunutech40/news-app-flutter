import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/features/auth/presentation/pages/login_page.dart';
import 'package:news_app/features/auth/presentation/pages/register_page.dart';
import 'package:news_app/features/news/presentation/cubit/category_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/news_feed_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/trending_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/search_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/article_detail_cubit.dart';
import 'package:news_app/features/news/presentation/pages/news_feed_page.dart';
import 'package:news_app/features/news/presentation/pages/news_search_page.dart';
import 'package:news_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:news_app/features/auth/presentation/pages/profile_page.dart';
import 'package:news_app/features/splash/presentation/pages/splash_page.dart';
import 'package:news_app/injection_container.dart';

class AppRouter {
  final AuthBloc authBloc;

  /// [rootNavigatorKey] adalah kunci utama yang disuntikkan ke MaterialApp.router.
  /// Ini SANGAT krusial untuk fitur GlobalAlertBloc. Dengan kunci statis ini,
  /// fungsi utilitas seperti `UIHelpers.showNetworkBottomSheet` bisa memunculkan
  /// UI overlay (Alert/BottomSheet) dari mana saja tanpa butuh BuildContext spesifik halaman.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    // =========================================================================
    // GLOBAL REDIRECT LOGIC
    // =========================================================================
    // Fungsi ini dipanggil setiap kali ada perubahan rute atau perubahan state
    // di `refreshListenable` (yaitu Stream dari AuthBloc).
    // Ini menggaransi user tidak akan bisa masuk halaman terlarang.
    redirect: (context, state) {
      final authStatus = authBloc.state.status;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnSplash = state.matchedLocation == '/splash';

      // 1. Sedang inisialisasi aplikasi (cek token di lokal), tahan user di Splash
      if (authStatus == AuthStatus.initial && isOnSplash) {
        return null; // Tetap di rute saat ini (/splash)
      }

      // 2. Tidak punya akses (Unauthenticated) & mencoba akses halaman non-Auth
      //    > Paksa lempar ke Login Page
      if (authStatus == AuthStatus.unauthenticated && !isOnAuth) {
        return '/login';
      }

      // 3. Sudah punya akses (Authenticated) tapi mencoba buka Login/Register/Splash
      //    > Paksa tendang ke Dashboard Page (Tidak masuk akal user login ditawari login lagi)
      if (authStatus == AuthStatus.authenticated && (isOnAuth || isOnSplash)) {
        return '/dashboard';
      }

      return null; // Tidak ada pelanggaran, biarkan user lewat
    },
    // Merubah Stream (dari AuthBloc) menjadi tipe Listenable yang bisa dibaca GoRouter
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<CategoryCubit>()..load()),
            BlocProvider(create: (_) => sl<TrendingCubit>()..load()),
            BlocProvider(create: (_) => sl<NewsFeedCubit>()..load()),
          ],
          child: const NewsFeedPage(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<SearchCubit>(),
          child: const NewsSearchPage(),
        ),
      ),
      GoRoute(
        path: '/article/:slug',
        name: 'articleDetail',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return BlocProvider(
            create: (_) => sl<ArticleDetailCubit>(),
            child: NewsDetailPage(slug: slug),
          );
        },
      ),
    ],
  );
}

/// Converts a BLoC stream to a Listenable for GoRouter.refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
