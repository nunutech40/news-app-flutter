import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/category.dart';
import 'package:news_app/features/news/domain/repositories/news_repository.dart';
import 'package:news_app/features/news/domain/usecases/get_categories_usecase.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK USECASE (DELEGATION PATTERN)
// =============================================================================
// UseCase adalah "pintu resmi" ke Domain Layer. Karena semua UseCase news
// adalah pure delegation (tidak ada business rule sendiri), test di sini
// fokus memvalidasi DUA hal:
//   1. Return Integrity: Nilai yang dikembalikan repository diteruskan utuh.
//   2. Forwarding: Method repository yang tepat dipanggil dengan parameter yang tepat.
//
// UseCase TIDAK boleh menyembunyikan/mengubah data — jika itu terjadi,
// test ini yang akan mendeteksinya.
// =============================================================================

class MockNewsRepository extends Mock implements NewsRepository {}
class FakeCategory extends Fake implements Category {}

void main() {
  late GetCategoriesUseCase usecase;
  late MockNewsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeCategory());
  });

  setUp(() {
    mockRepository = MockNewsRepository();
    usecase = GetCategoriesUseCase(mockRepository);
  });

  final tCategories = [
    const Category(id: 1, name: 'Technology', slug: 'technology', description: '', isActive: true),
    const Category(id: 2, name: 'Sports', slug: 'sports', description: '', isActive: false),
  ];

  // ----- HAPPY PATH -----
  test('harus meneruskan List<Category> dari repository tanpa modifikasi apapun', () async {
    // Arrange
    when(() => mockRepository.getCategories()).thenAnswer((_) async => tCategories);

    // Act
    final result = await usecase();

    // Assert: data diteruskan utuh, count dan isi sama
    expect(result, tCategories);
    expect(result.length, 2);
    expect(result.first.slug, 'technology');
    verify(() => mockRepository.getCategories()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  // ----- EDGE PATH: LIST KOSONG -----
  test('harus meneruskan list kosong [] jika repository memang mengembalikan kosong', () async {
    // Arrange
    when(() => mockRepository.getCategories()).thenAnswer((_) async => []);

    // Act
    final result = await usecase();

    // Assert
    expect(result, isEmpty);
    verify(() => mockRepository.getCategories()).called(1);
  });

  // ----- ERROR PATH -----
  test('harus melempar kembali Exception jika repository gagal', () async {
    // Arrange
    when(() => mockRepository.getCategories()).thenThrow(Exception('Server down'));

    // Act & Assert
    expect(() => usecase(), throwsException);
    verify(() => mockRepository.getCategories()).called(1);
  });
}
