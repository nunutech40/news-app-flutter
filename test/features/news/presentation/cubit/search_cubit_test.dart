import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';
import 'package:news_app/features/news/presentation/cubit/search_cubit.dart';

class MockGetNewsFeedUseCase extends Mock implements GetNewsFeedUseCase {}

class FakeGetNewsFeedParams extends Fake implements GetNewsFeedParams {}

void main() {
  late SearchCubit cubit;
  late MockGetNewsFeedUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeGetNewsFeedParams());
  });

  setUp(() {
    mockUseCase = MockGetNewsFeedUseCase();
    cubit = SearchCubit(mockUseCase);
  });

  tearDown(() {
    cubit.close();
  });

  final tArticle1 = Article(
    id: 1,
    categoryId: 1,
    categoryName: 'Tech',
    authorName: 'Admin',
    title: 'Flutter Update 1',
    slug: 'flutter-1',
    description: 'Desc',
    imageUrl: 'img1.jpg',
    readTimeMinutes: 5,
    status: 'published',
  );

  final tArticle2 = Article(
    id: 2,
    categoryId: 1,
    categoryName: 'Tech',
    authorName: 'Admin',
    title: 'Flutter Update 2',
    slug: 'flutter-2',
    description: 'Desc',
    imageUrl: 'img2.jpg',
    readTimeMinutes: 5,
    status: 'published',
  );

  group('search', () {
    blocTest<SearchCubit, SearchState>(
      'harus emit [SearchInitial] jika kata kunci kosong atau hanya spasi',
      build: () => cubit,
      act: (cubit) => cubit.search('   '),
      expect: () => [
        isA<SearchInitial>(),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'harus emit [SearchLoading, SearchLoaded] ketika pencarian sukses dan dpt data array awal',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => (
              hero: null,
              feed: [tArticle1],
              totalPages: 2
            ));
        return cubit;
      },
      act: (cubit) => cubit.search('flutter'),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>()
            .having((s) => s.articles, 'articles', [tArticle1])
            .having((s) => s.currentPage, 'currentPage', 1)
            .having((s) => s.totalPages, 'totalPages', 2)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'harus emit [SearchLoading, SearchError] ketika usecase gagal',
      build: () {
        when(() => mockUseCase(any())).thenThrow(Exception('Server Timeout'));
        return cubit;
      },
      act: (cubit) => cubit.search('flutter'),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchError>().having((s) => s.message, 'message', contains('Server Timeout')),
      ],
    );
  });

  group('loadMore', () {
    blocTest<SearchCubit, SearchState>(
      'tidak ngapa-ngapain jika state bukan SearchLoaded',
      build: () => cubit,
      act: (cubit) => cubit.loadMore(),
      expect: () => [],
    );

    final tInitialState = SearchLoaded(
      articles: [tArticle1],
      currentPage: 1,
      totalPages: 2,
      isLoadingMore: false,
    );

    blocTest<SearchCubit, SearchState>(
      'harus emit SearchLoaded baru dengan isLoadingMore true lalu tambah article jika berhasil',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => (
              hero: null,
              feed: [tArticle2],
              totalPages: 2
            ));
        return cubit;
      },
      seed: () => tInitialState,
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        isA<SearchLoaded>().having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        isA<SearchLoaded>()
            .having((s) => s.articles, 'articles', [tArticle1, tArticle2]) // Gabung!
            .having((s) => s.currentPage, 'currentPage', 2)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'harus revert isLoadingMore menjadi false jika getNextPage gagal (Exception)',
      build: () {
        when(() => mockUseCase(any())).thenThrow(Exception('No Data'));
        return cubit;
      },
      seed: () => tInitialState,
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        isA<SearchLoaded>().having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        isA<SearchLoaded>()
            .having((s) => s.articles, 'articles', [tArticle1]) // Tetap sama seperti awal
            .having((s) => s.currentPage, 'currentPage', 1)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse), // Kembali false
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'tidak ngapa-ngapain jika hasMore false (sudah halaman akhir)',
      build: () => cubit,
      seed: () => SearchLoaded(
        articles: [tArticle1],
        currentPage: 2,
        totalPages: 2, // hasMore = false
        isLoadingMore: false,
      ),
      act: (cubit) => cubit.loadMore(),
      expect: () => [],
      verify: (_) => verifyNever(() => mockUseCase(any())),
    );
  });
}
