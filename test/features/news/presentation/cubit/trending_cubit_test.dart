import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';
import 'package:news_app/features/news/presentation/cubit/trending_cubit.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK CUBIT (NEWS FEATURE — TrendingCubit)
// =============================================================================
// TrendingCubit mirip dengan CategoryCubit, hanya mendelegasikan ke UseCase
// tapi dengan parameter yang sudah "di-hardcode" (category: 'technology', limit: 5).
//
// SKENARIO WAJIB:
//   load():
//     a. Happy Path: emit [Loading, Loaded] dengan list artikel dari UseCase.
//        Juga verifikasi parameter 'technology' dan limit 5 diteruskan.
//     b. Error Path: UseCase throw Exception → emit [Loading, Error].
// =============================================================================

class MockGetNewsFeedUseCase extends Mock implements GetNewsFeedUseCase {}
class FakeGetNewsFeedParams extends Fake implements GetNewsFeedParams {}

void main() {
  late TrendingCubit cubit;
  late MockGetNewsFeedUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeGetNewsFeedParams());
  });

  setUp(() {
    mockUseCase = MockGetNewsFeedUseCase();
    cubit = TrendingCubit(mockUseCase);
  });

  tearDown(() => cubit.close());

  final tArticles = [
    Article(
      id: 1, categoryId: 1, categoryName: 'Tech', authorName: 'Nunu',
      title: 'Trending 1', slug: 'trend-1', description: 'desc',
      imageUrl: 'img.jpg', readTimeMinutes: 3, status: 'published',
    ),
    Article(
      id: 2, categoryId: 1, categoryName: 'Tech', authorName: 'Nunu',
      title: 'Trending 2', slug: 'trend-2', description: 'desc',
      imageUrl: 'img.jpg', readTimeMinutes: 2, status: 'published',
    ),
  ];

  final tResult = (hero: null as Article?, feed: tArticles, totalPages: 1);

  // ---------------------------------------------------------------------------
  // load()
  // ---------------------------------------------------------------------------
  group('load', () {
    // ----- HAPPY PATH -----
    blocTest<TrendingCubit, TrendingState>(
      'harus emit [Loading, Loaded] dengan artikel trending dan meneruskan parameter yang tepat ke UseCase',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => tResult);
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<TrendingLoading>(),
        isA<TrendingLoaded>().having((s) => s.articles, 'articles', tArticles),
      ],
      verify: (_) {
        // Verifikasi bahwa parameter hardcode (technology, limit 5, no hero) benar dikirim
        final capturedParams = verify(() => mockUseCase(captureAny())).captured.first as GetNewsFeedParams;
        expect(capturedParams.category, 'technology');
        expect(capturedParams.limit, 5);
        expect(capturedParams.includeHero, false);
      },
    );

    // ----- ERROR PATH -----
    blocTest<TrendingCubit, TrendingState>(
      'harus emit [Loading, Error] jika UseCase melempar Exception',
      build: () {
        when(() => mockUseCase(any())).thenThrow(Exception('Trending API down'));
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<TrendingLoading>(),
        isA<TrendingError>().having((s) => s.message, 'message', contains('Trending API down')),
      ],
    );
  });
}
