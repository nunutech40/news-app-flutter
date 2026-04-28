import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/core/utils/date_helper.dart';
import 'package:news_app/core/widgets/empty_view.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/presentation/cubit/search_cubit.dart';

class NewsSearchPage extends StatefulWidget {
  const NewsSearchPage({super.key});

  @override
  State<NewsSearchPage> createState() => _NewsSearchPageState();
}

class _NewsSearchPageState extends State<NewsSearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<SearchCubit>().loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<SearchCubit>().search(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search App Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Removed back button since this is a root tab

                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        autofocus: true,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari berita (mis. politik, olahraga)...',
                          hintStyle: TextStyle(
                              color: AppTheme.textMuted.withOpacity(0.5),
                              fontSize: 14),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppTheme.textMuted, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Results Body ──
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchInitial) {
                    return const Center(
                      child: EmptyView(
                        icon: Icons.manage_search_rounded,
                        title: 'Telusuri Berita',
                        message: 'Ketikkan kata kunci untuk mencari berita.',
                      ),
                    );
                  }

                  if (state is SearchLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor),
                    );
                  }

                  if (state is SearchError) {
                    return Center(
                      child: EmptyView(
                        icon: Icons.error_outline_rounded,
                        title: 'Pencarian Gagal',
                        message: state.message,
                      ),
                    );
                  }

                  if (state is SearchLoaded) {
                    if (state.articles.isEmpty) {
                      return const Center(
                        child: EmptyView(
                          icon: Icons.search_off_rounded,
                          title: 'Tidak Ditemukan',
                          message: 'Tidak ada berita yang cocok dengan kata kunci.',
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      itemCount: state.articles.length + 1,
                      separatorBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                          color: AppTheme.textMuted.withOpacity(0.15),
                          height: 1,
                        ),
                      ),
                      itemBuilder: (context, i) {
                        if (i == state.articles.length) {
                          if (state.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        final article = state.articles[i];
                        return _SearchListCard(article: article);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Card (Can be extracted later) ──────────────────────────────────
class _SearchListCard extends StatelessWidget {
  final Article article;

  const _SearchListCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Nyambung ke halaman detail yang udah dibuat sesuai instruksi User
        context.push('/article/${article.slug}');
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
