import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';
import 'package:news_app/features/news/presentation/cubit/explore_cubit.dart';

class MockGetNewsFeedUseCase extends Mock implements GetNewsFeedUseCase {}

class FakeGetNewsFeedParams extends Fake implements GetNewsFeedParams {}

void main() {
  late ExploreCubit cubit;
  late MockGetNewsFeedUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeGetNewsFeedParams());
  });

  setUp(() {
    mockUseCase = MockGetNewsFeedUseCase();
    cubit = ExploreCubit(mockUseCase);
  });

  tearDown(() {
    cubit.close();
  });

  final tArticle = Article(
    id: 1,
    categoryId: 1,
    categoryName: 'Tech',
    authorName: 'Admin',
    title: 'Test Article',
    slug: 'test',
    description: 'Desc',
    imageUrl: 'img.jpg',
    readTimeMinutes: 5,
    status: 'published',
  );

  group('loadAllSections', () {
    blocTest<ExploreCubit, ExploreState>(
      'harus emit [loading] all, lalu berurutan loaded: sports (500ms), tech (1500ms), business (2500ms) saat semua sukses',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => (
              hero: null,
              feed: [tArticle],
              totalPages: 1
            ));
        return cubit;
      },
      act: (cubit) => cubit.loadAllSections(),
      wait: const Duration(milliseconds: 3000), // Tunggu minimal 2500ms
      expect: () {
        // 1. Initial State Loading semua
        final s1 = const ExploreState(
          techStatus: FetchStatus.loading,
          businessStatus: FetchStatus.loading,
          sportsStatus: FetchStatus.loading,
        );

        // 2. Pertama yang muncul adalah Sports (karena delay tercepat 500ms)
        final s2 = s1.copyWith(
          sportsStatus: FetchStatus.loaded,
          sportsArticles: [tArticle],
        );

        // 3. Kedua yang muncul adalah Tech (karena delay menengah 1500ms)
        final s3 = s2.copyWith(
          techStatus: FetchStatus.loaded,
          techArticles: [tArticle],
        );

        // 4. Terakhir yang muncul adalah Business (karena delay terlama 2500ms)
        final s4 = s3.copyWith(
          businessStatus: FetchStatus.loaded,
          businessArticles: [tArticle],
        );

        return [s1, s2, s3, s4];
      },
      verify: (_) {
        // Pastikan dipanggil 3 kali dengan paremeter yang berbeda (tech, business, sports)
        verify(() => mockUseCase(any())).called(3);
      },
    );

    blocTest<ExploreCubit, ExploreState>(
      'harus emit error dengan urutan delay sesuai kecepatannya jika gagal semua',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => throw Exception('Timeout API'));
        return cubit;
      },
      act: (cubit) => cubit.loadAllSections(),
      // Walaupun melempar exception, usecase dijalankan tanpa delay (throw langsung). 
      // Delay hanya dieksekusi jika onSuccess (.then()). Namun pada catchError di Cubit tidak ada delay!
      // Jadi jika throw, catchError tereksekusi INSTAN sebelum Future.delayed tertekan.
      // Urutan catchError ini biasanya bergantung pada urutan eksekusi synchronous .then().catchError() 
      // Karena dieksekusi berurutan per baris (Tech -> Business -> Sports), maka error throw akan terpental sesuai urutan pemanggilan di Cubit!
      expect: () => [
        const ExploreState(
          techStatus: FetchStatus.loading,
          businessStatus: FetchStatus.loading,
          sportsStatus: FetchStatus.loading,
        ),
        // Error Tech melempar terlebih dahulu
        const ExploreState(
          techStatus: FetchStatus.error,
          businessStatus: FetchStatus.loading,
          sportsStatus: FetchStatus.loading,
        ),
        // Disusul Error Business
        const ExploreState(
          techStatus: FetchStatus.error,
          businessStatus: FetchStatus.error,
          sportsStatus: FetchStatus.loading,
        ),
        // Diakhiri Error Sports
        const ExploreState(
          techStatus: FetchStatus.error,
          businessStatus: FetchStatus.error,
          sportsStatus: FetchStatus.error,
        ),
      ],
    );
  });
}
