import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';
import 'package:news_app/features/news/domain/usecases/get_news_feed_usecase.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

void main() {
  late GetNewsFeedUseCase usecase;
  late MockNewsRepository mockRepository;

  setUp(() {
    mockRepository = MockNewsRepository();
    usecase = GetNewsFeedUseCase(mockRepository);
  });

  final tHero = Article(
    id: 99,
    categoryId: 1,
    categoryName: 'Technology',
    authorName: 'Nunu',
    title: 'Hero Article',
    slug: 'hero-article',
    description: 'Hero desc',
    imageUrl: 'hero.jpg',
    readTimeMinutes: 5,
    status: 'published',
    publishedAt: DateTime(2026, 4, 2),
  );

  final tFeed = [
    Article(
      id: 1,
      categoryId: 1,
      categoryName: 'Technology',
      authorName: 'Nunu',
      title: 'Article 1',
      slug: 'article-1',
      description: 'desc',
      imageUrl: 'img.jpg',
      readTimeMinutes: 3,
      status: 'published',
    ),
  ];

  final tResult = (hero: tHero as Article?, feed: tFeed, totalPages: 3);

  // ----- HAPPY PATH (DEFAULT PARAMS) -----
  test('harus meneruskan Record ({hero, feed, totalPages}) dari repository tanpa modifikasi', () async {
    // Arrange
    when(() => mockRepository.getFeed(
          category: any(named: 'category'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          includeHero: any(named: 'includeHero'),
        )).thenAnswer((_) async => tResult);

    // Act
    final result = await usecase(const GetNewsFeedParams());

    // Assert: Record diteruskan utuh
    expect(result.hero?.slug, 'hero-article');
    expect(result.feed.length, 1);
    expect(result.totalPages, 3);

    // Verifikasi parameter default diteruskan dengan benar ke repository
    verify(() => mockRepository.getFeed(
          category: null,
          page: 1,
          limit: 10,
          includeHero: true,
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  // ----- HAPPY PATH (DENGAN CUSTOM PARAMS) -----
  test('harus meneruskan parameter filter kategori dan pagination ke repository dengan tepat', () async {
    // Arrange
    when(() => mockRepository.getFeed(
          category: any(named: 'category'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          includeHero: any(named: 'includeHero'),
        )).thenAnswer((_) async => (hero: null, feed: <Article>[], totalPages: 1));

    // Act
    await usecase(const GetNewsFeedParams(
      category: 'sports',
      page: 3,
      limit: 5,
      includeHero: false,
    ));

    // Assert: semua custom params diteruskan dengan benar
    verify(() => mockRepository.getFeed(
          category: 'sports',
          page: 3,
          limit: 5,
          includeHero: false,
        )).called(1);
  });

  // ----- EDGE PATH: HERO NULL -----
  test('harus meneruskan Record dengan hero null jika repository memberikan null', () async {
    // Arrange
    when(() => mockRepository.getFeed(
          category: any(named: 'category'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          includeHero: any(named: 'includeHero'),
        )).thenAnswer((_) async => (hero: null, feed: <Article>[], totalPages: 1));

    // Act
    final result = await usecase(const GetNewsFeedParams());

    // Assert
    expect(result.hero, isNull);
    expect(result.feed, isEmpty);
    expect(result.totalPages, 1);
  });

  // ----- ERROR PATH -----
  test('harus melempar kembali Exception jika repository gagal', () async {
    // Arrange
    when(() => mockRepository.getFeed(
          category: any(named: 'category'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          includeHero: any(named: 'includeHero'),
        )).thenThrow(Exception('Network failure'));

    // Act & Assert
    expect(() => usecase(const GetNewsFeedParams()), throwsException);
  });
}
