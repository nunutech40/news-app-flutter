import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_article_usecase.dart';
import 'package:news_app/features/news/domain/usecases/check_bookmark_status_usecase.dart';
import 'package:news_app/features/news/domain/usecases/toggle_bookmark_usecase.dart';
import 'package:news_app/features/news/presentation/cubit/article_detail_cubit.dart';

class MockGetArticleUseCase extends Mock implements GetArticleUseCase {}
class MockCheckBookmarkStatusUseCase extends Mock implements CheckBookmarkStatusUseCase {}
class MockToggleBookmarkUseCase extends Mock implements ToggleBookmarkUseCase {}
class FakeArticle extends Fake implements Article {}

void main() {
  late ArticleDetailCubit cubit;
  late MockGetArticleUseCase mockGetUseCase;
  late MockCheckBookmarkStatusUseCase mockCheckBookmarkUseCase;
  late MockToggleBookmarkUseCase mockToggleBookmarkUseCase;

  setUpAll(() {
    registerFallbackValue(FakeArticle());
  });

  setUp(() {
    mockGetUseCase = MockGetArticleUseCase();
    mockCheckBookmarkUseCase = MockCheckBookmarkStatusUseCase();
    mockToggleBookmarkUseCase = MockToggleBookmarkUseCase();
    
    cubit = ArticleDetailCubit(
      mockGetUseCase,
      mockCheckBookmarkUseCase,
      mockToggleBookmarkUseCase,
    );
  });

  tearDown(() => cubit.close());

  const tSlug = 'test-slug';
  final tArticle = Article(
    id: 1,
    categoryId: 1,
    categoryName: 'Tech',
    authorName: 'Admin',
    title: 'Test',
    slug: tSlug,
    description: 'Desc',
    imageUrl: 'img.jpg',
    readTimeMinutes: 5,
    status: 'published',
  );

  group('loadArticle', () {
    blocTest<ArticleDetailCubit, ArticleDetailState>(
      'harus emit [Loading, Loaded] dengan status bookmarked yang disesuaikan saat load sukses',
      build: () {
        when(() => mockGetUseCase(tSlug)).thenAnswer((_) async => tArticle);
        when(() => mockCheckBookmarkUseCase(tSlug)).thenAnswer((_) async => true);
        return cubit;
      },
      act: (cubit) => cubit.loadArticle(tSlug),
      expect: () => [
        isA<ArticleDetailLoading>(),
        isA<ArticleDetailLoaded>()
            .having((s) => s.article, 'article', tArticle)
            .having((s) => s.isBookmarked, 'isBookmarked', isTrue),
      ],
      verify: (_) {
        verify(() => mockGetUseCase(tSlug)).called(1);
        verify(() => mockCheckBookmarkUseCase(tSlug)).called(1);
      },
    );

    blocTest<ArticleDetailCubit, ArticleDetailState>(
      'harus emit [Loading, Error] jika getArticle lempar exception',
      build: () {
        when(() => mockGetUseCase(tSlug)).thenThrow(Exception('Not Found'));
        return cubit;
      },
      act: (cubit) => cubit.loadArticle(tSlug),
      expect: () => [
        isA<ArticleDetailLoading>(),
        isA<ArticleDetailError>().having((s) => s.message, 'message', contains('Not Found')),
      ],
    );
  });

  group('toggleBookmark', () {
    blocTest<ArticleDetailCubit, ArticleDetailState>(
      'optimistic update: ubah isBookmarked jadi true lalu simpan asinkron saat tToggleUseCase sukses',
      build: () {
        when(() => mockToggleBookmarkUseCase(any())).thenAnswer((_) async => Future.value());
        return cubit;
      },
      seed: () => ArticleDetailLoaded(tArticle, isBookmarked: false),
      act: (cubit) => cubit.toggleBookmark(),
      expect: () => [
        isA<ArticleDetailLoaded>()
            .having((s) => s.article, 'article', tArticle)
            .having((s) => s.isBookmarked, 'isBookmarked', isTrue),
      ],
      verify: (_) => verify(() => mockToggleBookmarkUseCase(tArticle)).called(1),
    );

    blocTest<ArticleDetailCubit, ArticleDetailState>(
      'optimistic update revert: ubah isBookmarked jadi true, tapi karena throw, balik jadi false',
      build: () {
        when(() => mockToggleBookmarkUseCase(any())).thenThrow(Exception('Storage full'));
        return cubit;
      },
      seed: () => ArticleDetailLoaded(tArticle, isBookmarked: false),
      act: (cubit) => cubit.toggleBookmark(),
      expect: () => [
        // 1. Optimistic (berubah ke true)
        isA<ArticleDetailLoaded>().having((s) => s.isBookmarked, 'isBookmarked', isTrue),
        // 2. Revert karena error (kembali false)
        isA<ArticleDetailLoaded>().having((s) => s.isBookmarked, 'isBookmarked', isFalse),
      ],
    );
  });
}
