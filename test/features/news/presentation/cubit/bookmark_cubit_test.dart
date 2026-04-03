import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/usecases/get_bookmarks_usecase.dart';
import 'package:news_app/features/news/presentation/cubit/bookmark_cubit.dart';

class MockGetBookmarksUseCase extends Mock implements GetBookmarksUseCase {}

void main() {
  late BookmarkCubit cubit;
  late MockGetBookmarksUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetBookmarksUseCase();
    cubit = BookmarkCubit(mockUseCase);
  });

  tearDown(() => cubit.close());

  final tArticle = Article(
    id: 1,
    categoryId: 1,
    categoryName: 'Tech',
    authorName: 'Admin',
    title: 'Test Article',
    slug: 'test-article',
    description: 'Desc',
    imageUrl: 'img.jpg',
    readTimeMinutes: 5,
    status: 'published',
  );

  group('loadBookmarks', () {
    blocTest<BookmarkCubit, BookmarkState>(
      'harus emit [BookmarkLoading, BookmarkLoaded] ketika berhasil mendapatkan bookmark',
      build: () {
        when(() => mockUseCase()).thenAnswer((_) async => [tArticle]);
        return cubit;
      },
      act: (cubit) => cubit.loadBookmarks(),
      expect: () => [
        isA<BookmarkLoading>(),
        isA<BookmarkLoaded>().having((s) => s.articles, 'articles', [tArticle]),
      ],
      verify: (_) => verify(() => mockUseCase()).called(1),
    );

    blocTest<BookmarkCubit, BookmarkState>(
      'harus emit [BookmarkLoading, BookmarkLoaded] dengan list kosong saat tidak ada bookmark',
      build: () {
        when(() => mockUseCase()).thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.loadBookmarks(),
      expect: () => [
        isA<BookmarkLoading>(),
        isA<BookmarkLoaded>().having((s) => s.articles, 'articles', isEmpty),
      ],
    );

    blocTest<BookmarkCubit, BookmarkState>(
      'harus emit [BookmarkLoading, BookmarkError] ketika terjadi Exception',
      build: () {
        when(() => mockUseCase()).thenThrow(Exception('Gagal akses memori'));
        return cubit;
      },
      act: (cubit) => cubit.loadBookmarks(),
      expect: () => [
        isA<BookmarkLoading>(),
        isA<BookmarkError>().having((s) => s.message, 'message', contains('Gagal akses memori')),
      ],
    );
  });
}
