import 'package:flutter/material.dart';
import 'package:news_app/core/theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
          ),
          cursorColor: AppTheme.primaryColor,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Widget khusus untuk Password yang berdiri sendiri (*Self-Contained State*).
/// Tujuannya agar Halaman Induk (seperti LoginPage) tidak perlu kotor oleh 
/// variabel `obscureText` dan `setState` yang akan me-render ulang seluruh halaman.
class AuthPasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  const AuthPasswordTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  @override
  State<AuthPasswordTextField> createState() => _AuthPasswordTextFieldState();
}

class _AuthPasswordTextFieldState extends State<AuthPasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    // Kita gunakan ulang desain AuthTextField yang sudah baku, 
    // namun State Ikon Mata dikurung sepenuhnya di dalam lingkup Widget kecil ini.
    return AuthTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline_rounded,
      validator: widget.validator,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        onPressed: () {
          // Hanya me-render ulang 1 baris kolom textfield ini saja, bukan 1 layar Hp!
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}
