import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/auth/data/services/google_oauth_service.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:news_app/core/utils/validators.dart';
import 'package:news_app/core/utils/snackbar_mixin.dart';
import 'package:news_app/core/constants/api_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin, SnackbarMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error && state.errorMessage != null) {
            final msg = state.errorMessage!;
            // Ignore network errors, they are handled completely by GlobalAlertBloc
            if (msg.contains('No internet connection') || msg.contains('Connection timed out')) {
              return;
            }

            // Pesan error reguler seperti salah password dsb, gunakan SnackBar
            showErrorSnackbar(msg);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusLg),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.35),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.newspaper_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Title
                          Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 40),

                          // Email field
                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: 16),

                          // Password field (Isolated State untuk Re-rendered Performance)
                          AuthPasswordTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            validator: AppValidators.validatePassword,
                          ),
                          const SizedBox(height: 32),

                          // Login button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading =
                                  state.status == AuthStatus.loading;
                              return _GradientButton(
                                text: 'Sign In',
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _onLogin,
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // --- Social Login Divider ---
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppTheme.surfaceElevated)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Or sign in with',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: AppTheme.surfaceElevated)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // --- Social Login Buttons ---
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state.status == AuthStatus.loading;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _SocialButton(
                                    iconPath: 'assets/images/google_icon.png', // Fallback to an icon if you want, or use a Widget
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            context.read<AuthBloc>().add(
                                              AuthOAuthLoginRequested(
                                                GoogleOAuthService(
                                                  serverClientId: ApiConstants.googleWebClientId,
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                  // Apple button bisa ditambah di sini
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 32),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.textMuted),
                              ),
                              GestureDetector(
                                onTap: () => context.pushNamed('register'),
                                child: Text(
                                  'Sign Up',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.accentColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.text,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppTheme.primaryGradient : null,
        color: onPressed == null ? AppTheme.textMuted.withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.iconPath,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.surfaceElevated),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Image.network( // Menggunakan network image sementara
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
              width: 28,
              height: 28,
            ),
          ),
        ),
      ),
    );
  }
}
