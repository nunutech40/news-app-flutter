import 'package:flutter/material.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/core/utils/ui_helpers.dart';

/// Mixin tangguh untuk menyisipkan kemampuan pendeteksian dan visualisasi
/// error (baik Jaringan maupun Normal) secara instan ke dalam State apa pun.
///
/// Penggunaan:
/// ```dart
/// class _MyPageState extends State<MyPage> with NetworkErrorMixin { ... }
/// 
/// // Di dalam BlocListener:
/// if (state.status == Error) handleNetworkError(state.errorMessage!, _retryFunction);
/// ```
mixin NetworkErrorMixin<T extends StatefulWidget> on State<T> {
  /// Secara otomatis memilah antara Error Jaringan (Muncul BottomSheet)
  /// atau Error Logika/Server Biasa (Muncul SnackBar standar).
  void handleNetworkError(String errorMessage, VoidCallback onTryAgain) {
    if (errorMessage.contains('No internet connection')) {
      UIHelpers.showNetworkBottomSheet(context, false, onTryAgain);
    } else if (errorMessage.contains('Connection timed out')) {
      UIHelpers.showNetworkBottomSheet(context, true, onTryAgain);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: AppTheme.surfaceElevated,
        ),
      );
    }
  }
}
