import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';
import 'package:news_app/features/news/domain/usecases/check_bookmark_status_usecase.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

void main() {
  late CheckBookmarkStatusUseCase usecase;
  late MockNewsRepository mockRepository;

  setUp(() {
    mockRepository = MockNewsRepository();
    usecase = CheckBookmarkStatusUseCase(mockRepository);
  });

  const tSlug = 'test-slug';

  test('harus mendelegasikan pemanggilan isBookmarked(slug) ke repository dan mengembalikan boolean', () async {
    // Arrange
    when(() => mockRepository.isBookmarked(any())).thenAnswer((_) async => true);

    // Act
    final result = await usecase(tSlug);

    // Assert
    expect(result, isTrue);
    verify(() => mockRepository.isBookmarked(tSlug)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('harus melempar Exception tanpa membungkusnya secara paksa jika repository gagal', () async {
    // Arrange
    when(() => mockRepository.isBookmarked(any())).thenThrow(Exception('Unreadable'));

    // Act & Assert
    expect(() => usecase(tSlug), throwsException);
  });
}
