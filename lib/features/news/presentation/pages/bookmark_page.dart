import 'package:flutter/material.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/core/widgets/empty_view.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: EmptyView(
            icon: Icons.bookmark_border_rounded,
            title: 'Koleksi Kosong',
            message: 'Daftar berita tersimpan akan muncul di sini (Segera Hadir).',
          ),
        ),
      ),
    );
  }
}
