import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/core/utils/date_helper.dart';

void main() {
  group('DateHelper', () {
    group('timeAgo', () {
      test('harus kembalikan string kosong jika argumen null', () {
        expect(DateHelper.timeAgo(null), '');
      });

      test('harus kembalikan menit jika selisih waktu di bawah 1 jam', () {
        final date = DateTime.now().subtract(const Duration(minutes: 30));
        expect(DateHelper.timeAgo(date), '30m ago');
      });

      test('harus kembalikan jam jika selisih waktu di bawah 1 hari', () {
        final date = DateTime.now().subtract(const Duration(hours: 5));
        expect(DateHelper.timeAgo(date), '5h ago');
      });

      test('harus kembalikan hari jika selisih waktu lebih dari 24 jam', () {
        final date = DateTime.now().subtract(const Duration(days: 3));
        expect(DateHelper.timeAgo(date), '3d ago');
      });
    });
  });
}
