import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/features/auth/presentation/pages/login_page.dart';
import 'package:news_app/features/auth/presentation/pages/register_page.dart';
import 'package:news_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:news_app/features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authStatus = authBloc.state.status;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnSplash = state.matchedLocation == '/splash';

      // Still checking auth, stay on splash
      if (authStatus == AuthStatus.initial && isOnSplash) {
        return null;
      }

      // Not authenticated and not on auth pages
      if (authStatus == AuthStatus.unauthenticated && !isOnAuth) {
        return '/login';
      }

      // Authenticated and on auth pages or splash
      if (authStatus == AuthStatus.authenticated && (isOnAuth || isOnSplash)) {
        return '/dashboard';
      }

      return null;
    },
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
        builder: (context, state) => const DashboardPage(),
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
