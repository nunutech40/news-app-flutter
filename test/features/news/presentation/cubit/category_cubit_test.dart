import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/news/domain/entities/category.dart';
import 'package:news_app/features/news/domain/usecases/get_categories_usecase.dart';
import 'package:news_app/features/news/presentation/cubit/category_cubit.dart';

// =============================================================================
// ATURAN / PANDUAN UNIT TEST UNTUK CUBIT (NEWS FEATURE — CategoryCubit)
// =============================================================================
// CategoryCubit adalah State Machine sederhana dengan 2 metode: load() dan select().
//
// SKENARIO WAJIB:
//   load():
//     a. Happy Path: emit [Loading, Loaded] dengan list kategori dari UseCase.
//     b. Edge Path: list kosong → emit [Loading, Loaded] dengan list kosong.
//     c. Error Path: UseCase throw Exception → emit [Loading, Error].
//   select():
//     d. Guard Path: select() saat state masih Loading → tidak ada state baru (no-op).
//     e. Happy Path: select() saat state Loaded → emit Loaded baru dengan selectedSlug.
// =============================================================================

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

void main() {
  late CategoryCubit cubit;
  late MockGetCategoriesUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetCategoriesUseCase();
    cubit = CategoryCubit(mockUseCase);
  });

  tearDown(() => cubit.close());

  const tCategories = [
    Category(id: 1, name: 'Technology', slug: 'technology', description: '', isActive: true),
    Category(id: 2, name: 'Sports', slug: 'sports', description: '', isActive: true),
  ];

  // ---------------------------------------------------------------------------
  // load()
  // ---------------------------------------------------------------------------
  group('load', () {
    // ----- HAPPY PATH -----
    blocTest<CategoryCubit, CategoryState>(
      'harus emit [Loading, Loaded] dengan categories dari UseCase saat berhasil',
      build: () {
        when(() => mockUseCase()).thenAnswer((_) async => tCategories);
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<CategoryLoading>(),
        isA<CategoryLoaded>()
            .having((s) => s.categories, 'categories', tCategories)
            .having((s) => s.selectedSlug, 'selectedSlug', ''), // default kosong
      ],
      verify: (_) => verify(() => mockUseCase()).called(1),
    );

    // ----- EDGE PATH: LIST KOSONG -----
    blocTest<CategoryCubit, CategoryState>(
      'harus emit [Loading, Loaded] dengan list kosong jika server tidak punya kategori',
      build: () {
        when(() => mockUseCase()).thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<CategoryLoading>(),
        isA<CategoryLoaded>().having((s) => s.categories, 'categories', isEmpty),
      ],
    );

    // ----- ERROR PATH -----
    blocTest<CategoryCubit, CategoryState>(
      'harus emit [Loading, Error] dengan pesan error jika UseCase throw Exception',
      build: () {
        when(() => mockUseCase()).thenThrow(Exception('Network down'));
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<CategoryLoading>(),
        isA<CategoryError>().having(
          (s) => s.message,
          'message',
          contains('Network down'),
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // select()
  // ---------------------------------------------------------------------------
  group('select', () {
    // ----- GUARD PATH: state bukan Loaded -----
    blocTest<CategoryCubit, CategoryState>(
      'harus tidak emit state apapun (no-op) jika dipanggil saat state bukan CategoryLoaded',
      build: () => cubit, // state awal = CategoryInitial
      act: (cubit) => cubit.select('technology'),
      expect: () => [], // tidak ada state yang di-emit
    );

    // ----- HAPPY PATH: state sudah Loaded -----
    blocTest<CategoryCubit, CategoryState>(
      'harus emit CategoryLoaded baru dengan selectedSlug yang dipilh saat state sudah Loaded',
      build: () {
        when(() => mockUseCase()).thenAnswer((_) async => tCategories);
        return cubit;
      },
      seed: () => const CategoryLoaded(categories: tCategories, selectedSlug: ''),
      act: (cubit) => cubit.select('sports'),
      expect: () => [
        isA<CategoryLoaded>()
            .having((s) => s.selectedSlug, 'selectedSlug', 'sports')
            .having((s) => s.categories, 'categories', tCategories), // list tidak berubah
      ],
    );
  });
}
