import 'package:flutter/material.dart';
import 'package:news_app/core/theme/app_theme.dart';

/// Mixin yang dikhususkan untuk menempel pada class State (UI).
/// Dengan mixin ini, kita bisa memanggil fungsi Snackbar
/// seolah-olah fungsi tersebut adalah milik State itu sendiri.
mixin SnackbarMixin<T extends StatefulWidget> on State<T> {
  void showErrorSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.surfaceElevated,
      ),
    );
  }

  void showSuccessSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.primaryLight),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.surfaceElevated,
      ),
    );
  }
}
