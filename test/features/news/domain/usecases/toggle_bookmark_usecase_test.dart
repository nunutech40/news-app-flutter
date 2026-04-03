import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/article.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';
import 'package:news_app/features/news/domain/usecases/toggle_bookmark_usecase.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

class FakeArticle extends Fake implements Article {}

void main() {
  late ToggleBookmarkUseCase usecase;
  late MockNewsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeArticle());
  });

  setUp(() {
    mockRepository = MockNewsRepository();
    usecase = ToggleBookmarkUseCase(mockRepository);
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

  test('harus mendelegasikan pemanggilan toggleBookmark ke repository dengan entity Article yang tepat', () async {
    // Arrange
    when(() => mockRepository.toggleBookmark(any())).thenAnswer((_) async => Future.value());

    // Act
    await usecase(tArticle);

    // Assert
    verify(() => mockRepository.toggleBookmark(tArticle)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('harus melempar Exception ketika terjadi kegagalan saat menulis ke datasource', () async {
    // Arrange
    when(() => mockRepository.toggleBookmark(any())).thenThrow(Exception('Operation failed'));

    // Act & Assert
    expect(() => usecase(tArticle), throwsException);
  });
}
