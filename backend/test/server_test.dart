import 'package:test/test.dart';

import '../server.dart';

void main() {
  group('validateKycPayload', () {
    test('accepts valid payload', () {
      final result = validateKycPayload({
        'postcode': 'LA-11-W06-TC-10',
        'state': 'LAGOS',
        'bvn': '22233344455',
        'phone': '08031234567',
        'level': 3,
      });

      expect(result.isValid, isTrue);
    });

    test('rejects missing postcode', () {
      final result = validateKycPayload({
        'state': 'LAGOS',
        'bvn': '22233344455',
        'phone': '08031234567',
        'level': 3,
      });

      expect(result.isValid, isFalse);
      expect(result.message, contains('postcode'));
    });

    test('rejects invalid BVN format', () {
      final result = validateKycPayload({
        'postcode': 'LA-11-W06-TC-10',
        'state': 'LAGOS',
        'bvn': '123',
        'phone': '08031234567',
        'level': 3,
      });

      expect(result.isValid, isFalse);
      expect(result.message, contains('bvn'));
    });
  });
}
