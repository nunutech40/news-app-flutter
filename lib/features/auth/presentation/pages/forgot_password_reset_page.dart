import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:news_app/injection_container.dart';

class ForgotPasswordResetPage extends StatefulWidget {
  final String firebaseIdToken;

  const ForgotPasswordResetPage({super.key, required this.firebaseIdToken});

  @override
  State<ForgotPasswordResetPage> createState() => _ForgotPasswordResetPageState();
}

class _ForgotPasswordResetPageState extends State<ForgotPasswordResetPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<ForgotPasswordCubit>().submitNewPassword(
        firebaseIdToken: widget.firebaseIdToken,
        newPassword: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ForgotPasswordCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buat Password Baru'),
          backgroundColor: AppTheme.backgroundDark,
          elevation: 0,
        ),
        body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
          listener: (context, state) {
            if (state is ForgotPasswordError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
              );
            } else if (state is PasswordResetSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password berhasil diubah! Silakan login kembali.'),
                  backgroundColor: AppTheme.success,
                ),
              );
              // Kembali ke halaman login dan hapus stack sebelumnya
              context.go('/login');
            }
          },
          builder: (context, state) {
            final isLoading = state is ForgotPasswordLoading;
            
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Password Baru',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Buat password baru yang kuat dan mudah diingat. Minimal 6 karakter.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !isLoading,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.surfaceElevated),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password baru tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        enabled: !isLoading,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.surfaceElevated),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password tidak boleh kosong';
                          }
                          if (value != _passwordController.text) {
                            return 'Konfirmasi password tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: isLoading ? null : () => _onSubmit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Simpan Password Baru',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
