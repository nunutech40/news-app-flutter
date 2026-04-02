import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';
import 'package:news_app/features/news/presentation/cubit/news_feed_cubit.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK CUBIT (NEWS FEATURE — NewsFeedCubit)
// =============================================================================
// NewsFeedCubit lebih kompleks karena punya 3 method: load(), loadMore(), refresh().
//
// FOKUS TEST:
//   load():
//     a. Happy Path: emit [Loading, Loaded] dengan data lengkap (hero + feed + totalPages).
//     b. Error Path: UseCase throw → emit [Loading, Error].
//   loadMore():
//     c. Guard Path: state bukan Loaded atau isLoadingMore → no-op (tidak emit).
//     d. Guard Path: hasMore false (currentPage >= totalPages) → no-op.
//     e. Happy Path: emit [Loaded(isLoadingMore:true), Loaded(feed merged, page+1)].
//   refresh():
//     f. Delegasi ke load() — verifikasi UseCase dipanggil ulang.
// =============================================================================

class MockGetNewsFeedUseCase extends Mock implements GetNewsFeedUseCase {}
class FakeGetNewsFeedParams extends Fake implements GetNewsFeedParams {}

void main() {
  late NewsFeedCubit cubit;
  late MockGetNewsFeedUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeGetNewsFeedParams());
  });

  setUp(() {
    mockUseCase = MockGetNewsFeedUseCase();
    cubit = NewsFeedCubit(mockUseCase);
  });

  tearDown(() => cubit.close());

  // Artikel dummy
  final tHero = Article(
    id: 99, categoryId: 1, categoryName: 'Tech', authorName: 'Nunu',
    title: 'Hero Article', slug: 'hero', description: 'desc',
    imageUrl: 'img.jpg', readTimeMinutes: 5, status: 'published',
    publishedAt: DateTime(2026, 4, 2),
  );
  final tArticle1 = Article(
    id: 1, categoryId: 1, categoryName: 'Tech', authorName: 'Nunu',
    title: 'Article 1', slug: 'article-1', description: 'desc',
    imageUrl: 'img.jpg', readTimeMinutes: 3, status: 'published',
  );
  final tArticle2 = Article(
    id: 2, categoryId: 1, categoryName: 'Tech', authorName: 'Nunu',
    title: 'Article 2', slug: 'article-2', description: 'desc',
    imageUrl: 'img.jpg', readTimeMinutes: 2, status: 'published',
  );

  // ---------------------------------------------------------------------------
  // load()
  // ---------------------------------------------------------------------------
  group('load', () {
    // ----- HAPPY PATH -----
    blocTest<NewsFeedCubit, NewsFeedState>(
      'harus emit [Loading, Loaded] dengan hero+feed+totalPages dari UseCase',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async =>
            (hero: tHero as Article?, feed: [tArticle1], totalPages: 5));
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NewsFeedLoading>(),
        isA<NewsFeedLoaded>()
            .having((s) => s.hero?.slug, 'hero.slug', 'hero')
            .having((s) => s.feed.length, 'feed.length', 1)
            .having((s) => s.totalPages, 'totalPages', 5)
            .having((s) => s.currentPage, 'currentPage', 1),
      ],
    );

    // ----- ERROR PATH -----
    blocTest<NewsFeedCubit, NewsFeedState>(
      'harus emit [Loading, Error] jika UseCase melempar Exception',
      build: () {
        when(() => mockUseCase(any())).thenThrow(Exception('Server Error 500'));
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NewsFeedLoading>(),
        isA<NewsFeedError>().having((s) => s.message, 'message', contains('Server Error 500')),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // loadMore()
  // ---------------------------------------------------------------------------
  group('loadMore', () {
    // ----- GUARD PATH: state bukan NewsFeedLoaded -----
    blocTest<NewsFeedCubit, NewsFeedState>(
      'harus tidak emit apapun (no-op) jika state saat ini bukan NewsFeedLoaded',
      build: () => cubit, // state awal = NewsFeedInitial
      act: (cubit) => cubit.loadMore(),
      expect: () => [], // tidak ada state baru
      verify: (_) => verifyNever(() => mockUseCase(any())),
    );

    // ----- GUARD PATH: sudah di halaman terakhir (hasMore = false) -----
    blocTest<NewsFeedCubit, NewsFeedState>(
      'harus tidak emit apapun (no-op) jika currentPage sudah sama dengan totalPages',
      build: () => cubit,
      seed: () => NewsFeedLoaded(
        hero: tHero,
        feed: [tArticle1],
        currentPage: 3,
        totalPages: 3, // hasMore = false
      ),
      act: (cubit) => cubit.loadMore(),
      expect: () => [],
      verify: (_) => verifyNever(() => mockUseCase(any())),
    );

    // ----- HAPPY PATH: bisa load more -----
    blocTest<NewsFeedCubit, NewsFeedState>(
      'harus emit [Loaded(isLoadingMore:true), Loaded(merged feed, page+1)] saat loadMore berhasil',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async =>
            (hero: null, feed: [tArticle2], totalPages: 5));
        return cubit;
      },
      seed: () => NewsFeedLoaded(
        hero: tHero,
        feed: [tArticle1],
        currentPage: 1,
        totalPages: 5, // hasMore = true
      ),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        // State pertama: isLoadingMore = true
        isA<NewsFeedLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', true)
            .having((s) => s.currentPage, 'currentPage', 1),
        // State kedua: feed di-merge, halaman bertambah
        isA<NewsFeedLoaded>()
            .having((s) => s.feed.length, 'feed.length', 2) // artikel 1 + artikel 2
            .having((s) => s.currentPage, 'currentPage', 2)
            .having((s) => s.isLoadingMore, 'isLoadingMore', false),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // refresh()
  // ---------------------------------------------------------------------------
  group('refresh', () {
    blocTest<NewsFeedCubit, NewsFeedState>(
      'harus reset ke halaman 1 dan memanggil UseCase ulang saat refresh()',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async =>
            (hero: null, feed: [tArticle1], totalPages: 2));
        return cubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<NewsFeedLoading>(),
        isA<NewsFeedLoaded>().having((s) => s.currentPage, 'currentPage', 1),
      ],
      verify: (_) => verify(() => mockUseCase(any())).called(1),
    );
  });
}
