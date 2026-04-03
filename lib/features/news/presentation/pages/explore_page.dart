import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/presentation/cubit/explore_cubit.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  @override
  void initState() {
    super.initState();
    // Load pertama kali saat halaman diinisialisasi
    context.read<ExploreCubit>().loadAllSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Jelajah Topik',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
            onPressed: () => context.read<ExploreCubit>().loadAllSections(),
          ),
        ],
      ),
      body: BlocBuilder<ExploreCubit, ExploreState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              context.read<ExploreCubit>().loadAllSections();
              await Future.delayed(const Duration(seconds: 1)); // UX muter
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Scrollable dipaksa agar tetap bisa ditarik
              slivers: [
              SliverToBoxAdapter(
                child: _buildSection(
                  context,
                  title: '🚀 Top Teknologi',
                  status: state.techStatus,
                  articles: state.techArticles,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSection(
                  context,
                  title: '💼 Sorotan Bisnis',
                  status: state.businessStatus,
                  articles: state.businessArticles,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSection(
                  context,
                  title: '⚽ Kabar Olahraga',
                  status: state.sportsStatus,
                  articles: state.sportsArticles,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required FetchStatus status,
    required List<Article> articles,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: _buildSectionContent(status, articles),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(FetchStatus status, List<Article> articles) {
    if (status == FetchStatus.initial || status == FetchStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (status == FetchStatus.error) {
      return const Center(
        child: Text(
          'Gagal memuat.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    if (articles.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada berita.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: articles.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, i) {
        final article = articles[i];
        return GestureDetector(
          onTap: () => context.push('/article/${article.slug}'),
          child: Container(
            width: 140,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusMd),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: article.displayImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(color: AppTheme.surfaceCard),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppTheme.surfaceElevated),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
