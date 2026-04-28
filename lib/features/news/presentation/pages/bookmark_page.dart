import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/core/utils/date_helper.dart';
import 'package:news_app/core/widgets/empty_view.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/presentation/cubit/bookmark_cubit.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Koleksi Berita',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<BookmarkCubit, BookmarkState>(
        builder: (context, state) {
          if (state is BookmarkLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is BookmarkError) {
            return Center(
              child: EmptyView(
                icon: Icons.error_outline_rounded,
                title: 'Gagal Memuat Berita',
                message: state.message,
              ),
            );
          }

          if (state is BookmarkLoaded) {
            if (state.articles.isEmpty) {
              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async {
                  context.read<BookmarkCubit>().loadBookmarks();
                  // Efek tunggu sebentar biar animasi muter kelihatan
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: constraints.maxHeight,
                      alignment: Alignment.center,
                      child: const EmptyView(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Koleksi Kosong',
                        message: 'Daftar berita yang Anda simpan akan muncul di sini.',
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async {
                context.read<BookmarkCubit>().loadBookmarks();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: state.articles.length,
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(
                    color: AppTheme.textMuted.withOpacity(0.15),
                    height: 1,
                  ),
                ),
                itemBuilder: (context, i) {
                  return _BookmarkCard(article: state.articles[i]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Article article;

  const _BookmarkCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Pindah ke halaman detail
        await context.push('/article/${article.slug}');
        // Refresh saat kembali dari halaman detail (untuk antisipasi jika di-unsave dari detail!)
        if (context.mounted) {
          context.read<BookmarkCubit>().loadBookmarks();
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.categoryName.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.publishedAt.timeAgo,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: SizedBox(
                width: 90,
                height: 90,
                child: CachedNetworkImage(
                  imageUrl: article.displayImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surfaceCard),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppTheme.surfaceElevated),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
