import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';
import 'package:news_app/features/news/domain/usecases/get_bookmarks_usecase.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

void main() {
  late GetBookmarksUseCase usecase;
  late MockNewsRepository mockRepository;

  setUp(() {
    mockRepository = MockNewsRepository();
    usecase = GetBookmarksUseCase(mockRepository);
  });

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

  test('harus mendelegasikan pemanggilan ke repository.getBookmarks() dan mengembalikan List<Article>', () async {
    // Arrange
    when(() => mockRepository.getBookmarks()).thenAnswer((_) async => [tArticle]);

    // Act
    final result = await usecase();

    // Assert
    expect(result, isA<List<Article>>());
    expect(result.length, 1);
    expect(result.first.slug, 'test-article');
    verify(() => mockRepository.getBookmarks()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('harus melempar kembali Exception jika pemanggilan repository gagal', () async {
    // Arrange
    when(() => mockRepository.getBookmarks()).thenThrow(Exception('Failed to read SharedPreferences'));

    // Act & Assert
    expect(
      () => usecase(),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('Failed to read SharedPreferences'),
      )),
    );
    verify(() => mockRepository.getBookmarks()).called(1);
  });
}
