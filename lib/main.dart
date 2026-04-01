import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/core/router/app_router.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/injection_container.dart' as di;
import 'package:news_app/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Auth BLoC is global — provided at the top level
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
