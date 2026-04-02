import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/features/news/domain/entities/category.dart';

void main() {
  group('Category Entity', () {
    test('harus menganggap setara jika id dan slug sama walau deskripsi beda (Equatable func)', () {
      const c1 = Category(
        id: 1,
        name: 'Tech',
        slug: 'tech',
        description: 'deskripsi 1',
        isActive: true,
      );

      const c2 = Category(
        id: 1, // sama
        name: 'Technology', // beda
        slug: 'tech', // sama
        description: 'deskripsi bebeda rupa', // beda
        isActive: false, // beda
      );

      // Karena props = [id, slug], c1 dan c2 harus dianggap identik
      expect(c1 == c2, isTrue);
    });
  });
}
