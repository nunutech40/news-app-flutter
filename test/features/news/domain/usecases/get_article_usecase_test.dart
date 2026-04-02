import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';
import 'package:news_app/features/news/domain/usecases/get_article_usecase.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

void main() {
  late GetArticleUseCase usecase;
  late MockNewsRepository mockRepository;

  setUp(() {
    mockRepository = MockNewsRepository();
    usecase = GetArticleUseCase(mockRepository);
  });

  const tSlug = 'flutter-for-the-win';
  final tArticle = Article(
    id: 42,
    categoryId: 1,
    categoryName: 'Technology',
    authorName: 'Nunu Dev',
    title: 'Flutter for the Win',
    slug: tSlug,
    description: 'Short description here',
    content: 'Full article content here...',
    imageUrl: 'https://cdn.example.com/img.jpg',
    readTimeMinutes: 7,
    status: 'published',
    publishedAt: DateTime(2026, 4, 2),
  );

  // ----- HAPPY PATH -----
  test('harus meneruskan Article dari repository dan memverifikasi slug dikirim dengan tepat', () async {
    // Arrange
    when(() => mockRepository.getArticle(any())).thenAnswer((_) async => tArticle);

    // Act
    final result = await usecase(tSlug);

    // Assert: entity dikembalikan utuh tanpa modifikasi
    expect(result, isA<Article>());
    expect(result.slug, tSlug);
    expect(result.title, 'Flutter for the Win');
    expect(result.content, isNotNull); // Article detail punya content
    expect(result.readTimeMinutes, 7);

    // Verifikasi slug diteruskan ke repository tanpa diubah
    verify(() => mockRepository.getArticle(tSlug)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  // ----- EDGE PATH: ARTICLE TANPA CONTENT (LIST VIEW) -----
  test('harus meneruskan Article dengan content null tanpa crash (preview/list article)', () async {
    // Arrange: artikel dari daftar feed tidak punya content lengkap
    final tArticleNoContent = Article(
      id: 1,
      categoryId: 1,
      categoryName: 'Sports',
      authorName: 'Author',
      title: 'Sports News',
      slug: 'sports-news',
      description: 'Teaser only',
      content: null, // Tidak ada full content
      imageUrl: 'img.jpg',
      readTimeMinutes: 2,
      status: 'published',
    );
    when(() => mockRepository.getArticle(any())).thenAnswer((_) async => tArticleNoContent);

    // Act
    final result = await usecase('sports-news');

    // Assert: content null tidak menyebabkan crash di UseCase
    expect(result.content, isNull);
    expect(result.slug, 'sports-news');
  });

  // ----- ERROR PATH: SLUG TIDAK DITEMUKAN -----
  test('harus melempar Exception jika repository gagal menemukan artikel dengan slug tersebut', () async {
    // Arrange: server 404
    when(() => mockRepository.getArticle(any())).thenThrow(Exception('Article not found'));

    // Act & Assert
    expect(
      () => usecase('slug-yang-tidak-ada'),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('Article not found'),
      )),
    );
    verify(() => mockRepository.getArticle('slug-yang-tidak-ada')).called(1);
  });
}
