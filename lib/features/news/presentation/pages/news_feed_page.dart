import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/features/auth/presentation/widgets/edit_profile_bottom_sheet.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/entities/category.dart';
import 'package:news_app/features/news/presentation/cubit/category_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/news_feed_cubit.dart';
import 'package:news_app/features/news/presentation/cubit/trending_cubit.dart';
import 'package:shimmer/shimmer.dart';

class NewsFeedPage extends StatelessWidget {
  const NewsFeedPage({super.key});

  @override
  Widget build(BuildContext context) => const _NewsFeedView();
}

class _NewsFeedView extends StatefulWidget {
  const _NewsFeedView();

  @override
  State<_NewsFeedView> createState() => _NewsFeedViewState();
}

class _NewsFeedViewState extends State<_NewsFeedView> {
  final _scrollController = ScrollController();
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<NewsFeedCubit>().loadMore(
            category: _selectedCategory.isEmpty ? null : _selectedCategory,
          );
    }
  }

  void _onCategorySelected(String slug) {
    setState(() => _selectedCategory = slug);
    context.read<CategoryCubit>().select(slug);
    context.read<NewsFeedCubit>().load(
          category: slug.isEmpty ? null : slug,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceCard,
          onRefresh: () => context.read<NewsFeedCubit>().refresh(
                category: _selectedCategory.isEmpty ? null : _selectedCategory,
              ),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── App Bar ────────────────────────────────────────────────────
              const SliverToBoxAdapter(child: _NewsAppBar()),
              // ── Category Chips ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoading) return const _CategoryShimmer();
                    if (state is CategoryLoaded) {
                      return _CategoryChips(
                        categories: state.categories,
                        selectedSlug: state.selectedSlug,
                        onSelected: _onCategorySelected,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
        // ── Trending (Independent API Call) ────────────
        BlocBuilder<TrendingCubit, TrendingState>(
          builder: (context, state) {
            if (state is TrendingLoading) return const _TrendingShimmer();
            if (state is TrendingLoaded) return _TrendingSection(articles: state.articles);
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),

        // ── Feed Content (Latest News vertical) ─────────
        BlocBuilder<NewsFeedCubit, NewsFeedState>(
          builder: (context, state) {
            if (state is NewsFeedLoading) return const _FeedShimmer();
            if (state is NewsFeedLoaded) {
              return _FeedContent(state: state);
            }
                  if (state is NewsFeedError) {
                    return SliverFillRemaining(
                      child: _ErrorView(
                        message: state.message,
                        onRetry: () => context.read<NewsFeedCubit>().load(
                              category: _selectedCategory.isEmpty
                                  ? null
                                  : _selectedCategory,
                            ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _NewsAppBar extends StatelessWidget {
  const _NewsAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          // Logo / Title
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'AURORA ',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                TextSpan(
                  text: 'NEWS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _IconBtn(Icons.search_rounded, onTap: () {}),
          const SizedBox(width: 8),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state.user;
              final avatar = user?.avatarUrl;
              return GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    image: (avatar != null && avatar.isNotEmpty)
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(avatar),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (avatar == null || avatar.isEmpty)
                      ? const Icon(Icons.person_outline_rounded,
                          color: AppTheme.textSecondary, size: 20)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}

// ── Category Chips ────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String selectedSlug;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final all = [
      const Category(id: 0, name: 'All', slug: '', description: '', isActive: true),
      ...categories,
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = all[i];
          final isSelected = cat.slug == selectedSlug;
          return GestureDetector(
            onTap: () => onSelected(cat.slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textMuted.withOpacity(0.2),
                ),
              ),
              child: Text(
                cat.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Feed Content ──────────────────────────────────────────────────────────────
class _FeedContent extends StatelessWidget {
  final NewsFeedLoaded state;
  const _FeedContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Hero
        if (state.hero != null) ...[
          const SizedBox(height: 16),
          _HeroCard(article: state.hero!),
        ],
        // List
        const SizedBox(height: 20),
        _buildList(state.feed),
        // Load more indicator
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            ),
          ),
        if (!state.hasMore && state.feed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '— You\'re all caught up —',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildList(List<Article> articles) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Vertical Section (Latest News) ──
        const Padding(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 8),
          child: Text(
            'Latest Updates',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: AppTheme.textMuted.withOpacity(0.15),
                height: 1,
                thickness: 1,
              ),
            ),
            itemBuilder: (context, i) => _ListCard(article: articles[i]),
          ),
        ),
      ],
    );
  }
}

// ── Trending Section ──────────────────────────────────────────────────────────
class _TrendingSection extends StatelessWidget {
  final List<Article> articles;
  const _TrendingSection({required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Trending Now',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: articles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _HorizontalCard(article: articles[i]),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final Article article;
  const _HeroCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* navigate to detail */},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surfaceCard),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppTheme.surfaceElevated),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
                // Content
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.categoryName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'By ${article.authorName}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.white.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '${article.readTimeMinutes}m read',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Horizontal Card ───────────────────────────────────────────────────────────
class _HorizontalCard extends StatelessWidget {
  final Article article;
  const _HorizontalCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* navigate */},
      child: Container(
        width: 160, // Fixed width for horizontal scrolling items
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: article.displayImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surfaceElevated),
                  errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceElevated),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.categoryName.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List Card ─────────────────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final Article article;
  const _ListCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* navigate to detail */},
      child: Container(
        color: Colors.transparent, // Ensures the whole area is clickable
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Content (Left)
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
                    article.timeAgo,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Thumbnail (Right)
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


// ── Shimmer Loading ───────────────────────────────────────────────────────────
class _CategoryShimmer extends StatelessWidget {
  const _CategoryShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppTheme.surfaceCard,
          highlightColor: AppTheme.surfaceElevated,
          child: Container(
            width: 80,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingShimmer extends StatelessWidget {
  const _TrendingShimmer();

  Widget _box(double w, double h) => Shimmer.fromColors(
        baseColor: AppTheme.surfaceCard,
        highlightColor: AppTheme.surfaceElevated,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _box(120, 20),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => _box(160, 220),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FeedShimmer extends StatelessWidget {
  const _FeedShimmer();

  Widget _box(double w, double h) => Shimmer.fromColors(
        baseColor: AppTheme.surfaceCard,
        highlightColor: AppTheme.surfaceElevated,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero shimmer
            _box(w - 40, 300),
            const SizedBox(height: 20),
            // List shimmer
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  color: AppTheme.textMuted.withOpacity(0.15),
                  height: 1,
                  thickness: 1,
                ),
              ),
              itemBuilder: (_, __) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(60, 14),
                        const SizedBox(height: 8),
                        _box(w * 0.5, 18),
                        const SizedBox(height: 4),
                        _box(w * 0.4, 18),
                        const SizedBox(height: 12),
                        _box(40, 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _box(90, 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load news',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
