import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/core/utils/validators.dart';

void main() {
  group('AppValidators', () {
    group('validateEmail', () {
      test('harus mereturn pesan error jika email null', () {
        expect(AppValidators.validateEmail(null), 'Email is required');
      });

      test('harus mereturn pesan error jika email kosong', () {
        expect(AppValidators.validateEmail(''), 'Email is required');
        expect(AppValidators.validateEmail('   '), 'Email is required');
      });

      test('harus mereturn pesan error jika format email tidak valid', () {
        expect(AppValidators.validateEmail('invalid_email'), 'Please enter a valid email address');
        expect(AppValidators.validateEmail('user@domain'), 'Please enter a valid email address');
        expect(AppValidators.validateEmail('@domain.com'), 'Please enter a valid email address');
      });

      test('harus mereturn null (sukses) jika format email valid', () {
        expect(AppValidators.validateEmail('nunu@gmail.com'), isNull);
        expect(AppValidators.validateEmail('nunu.nugraha@company.co.id'), isNull);
      });
    });

    group('validatePassword', () {
      test('harus mereturn pesan error jika password null atau kosong', () {
        expect(AppValidators.validatePassword(null), 'Password is required');
        expect(AppValidators.validatePassword(''), 'Password is required');
      });

      test('harus mereturn pesan error jika password kurang dari 8 karakter', () {
        expect(AppValidators.validatePassword('1234567'), 'Password must be at least 8 characters');
      });

      test('harus mereturn null (sukses) jika password memenuhi syarat', () {
        expect(AppValidators.validatePassword('12345678'), isNull);
        expect(AppValidators.validatePassword('strong_password_123'), isNull);
      });
    });

    group('validateName', () {
      test('harus mereturn pesan error jika nama null atau kosong', () {
        expect(AppValidators.validateName(null), 'Name is required');
        expect(AppValidators.validateName('   '), 'Name is required');
      });

      test('harus mereturn pesan error jika nama kurang dari 3 karakter', () {
        expect(AppValidators.validateName('Nu'), 'Name must be at least 3 characters');
      });

      test('harus mereturn null (sukses) jika nama valid', () {
        expect(AppValidators.validateName('Nun'), isNull);
        expect(AppValidators.validateName('Nunu Nugraha'), isNull);
      });
    });
  });
}
