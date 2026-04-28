import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/core/utils/date_helper.dart';

void main() {
  group('DateTimeExtension', () {
    group('timeAgo', () {
      test('harus kembalikan string kosong jika argumen null', () {
        DateTime? date;
        expect(date.timeAgo, '');
      });

      test('harus kembalikan menit jika selisih waktu di bawah 1 jam', () {
        final date = DateTime.now().subtract(const Duration(minutes: 30));
        expect(date.timeAgo, '30m ago');
      });

      test('harus kembalikan jam jika selisih waktu di bawah 1 hari', () {
        final date = DateTime.now().subtract(const Duration(hours: 5));
        expect(date.timeAgo, '5h ago');
      });

      test('harus kembalikan hari jika selisih waktu lebih dari 24 jam', () {
        final date = DateTime.now().subtract(const Duration(days: 3));
        expect(date.timeAgo, '3d ago');
      });
    });
  });
}
