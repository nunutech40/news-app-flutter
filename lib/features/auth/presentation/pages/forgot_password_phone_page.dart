import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:news_app/injection_container.dart';

class ForgotPasswordPhonePage extends StatefulWidget {
  const ForgotPasswordPhonePage({super.key});

  @override
  State<ForgotPasswordPhonePage> createState() => _ForgotPasswordPhonePageState();
}

class _ForgotPasswordPhonePageState extends State<ForgotPasswordPhonePage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // Hilangkan awalan 0 jika user mengetiknya (karena butuh format +62)
      // Untuk sederhananya kita pakai langsung, atau format manual
      String phone = _phoneController.text.trim();
      if (phone.startsWith('0')) {
        phone = '+62${phone.substring(1)}';
      } else if (!phone.startsWith('+')) {
        phone = '+62$phone';
      }
      
      context.read<ForgotPasswordCubit>().requestOTP(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ForgotPasswordCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lupa Password'),
          backgroundColor: AppTheme.backgroundDark,
          elevation: 0,
        ),
        body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
          listener: (context, state) {
            if (state is ForgotPasswordError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
              );
            } else if (state is OTPRequestedSuccess) {
              // Pindah ke halaman verifikasi dengan membawa verificationId
              context.push(
                '/forgot-password/verify',
                extra: state.verificationId,
              );
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
                        'Lupa Password Anda?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Masukkan nomor telepon yang terdaftar. Kami akan mengirimkan kode OTP via SMS untuk mereset password Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !isLoading,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Nomor Telepon',
                          hintText: 'Contoh: 08123456789',
                          prefixIcon: const Icon(Icons.phone),
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
                            return 'Nomor telepon tidak boleh kosong';
                          }
                          if (value.length < 9) {
                            return 'Nomor telepon tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
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
                                'Kirim Kode OTP',
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
