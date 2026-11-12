import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/utils/validators.dart';

void main() {
  group('Form Validators Test Suite', () {
    test('Email validator validates student email format', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email('candidate@student.sliit.lk'), isNull);
    });

    test('Password validator requires minimum 6 characters', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('Phone validator checks length and emptiness', () {
      expect(Validators.phone(null), isNotNull);
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone('+94771234567'), isNull);
    });

    test('URL validator validates http and https schemes', () {
      expect(Validators.url('', true), isNull);
      expect(Validators.url('ftp://bad-url', true), isNotNull);
      expect(Validators.url('https://linkedin.com/in/alex', true), isNull);
    });
  });
}
