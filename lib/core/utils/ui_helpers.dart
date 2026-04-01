import 'package:flutter/material.dart';
import 'package:news_app/core/theme/app_theme.dart';

class UIHelpers {
  /// Menampilkan BottomSheet standar untuk error Jaringan (No Internet & Timeout).
  /// [isTimeout] true jika error adalah timeout, false jika no internet.
  /// [onTryAgain] callback block function untuk men-trigger ulang aksi sebelumnya.
  static void showNetworkBottomSheet(
      BuildContext context, bool isTimeout, VoidCallback onTryAgain) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusXl),
              topRight: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(
                isTimeout ? Icons.timer_off_outlined : Icons.wifi_off_rounded,
                size: 64,
                color: isTimeout ? AppTheme.accentColor : AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                isTimeout ? 'Request Timeout' : 'No Internet Connection',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isTimeout
                    ? 'The server took too long to respond. Please check your signal and try again.'
                    : 'Please check your Wi-Fi or mobile data network and try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Tutup bottomsheet
                    onTryAgain(); // Panggil ulang fungsi dari page pemanggil
                  },
                  child: const Text('Try Again',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
