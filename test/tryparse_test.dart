// Tests for the non-throwing tryParse* family (S1). Each returns the same
// value as its throwing sibling on valid input, and `null` (rather than
// throwing) on invalid input.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('tryParseInt', () {
    test('valid input matches parseInt', () {
      expect(tryParseInt('ยี่สิบเอ็ด'), 21);
      expect(tryParseInt('ยี่สิบเอ็ด'), parseInt('ยี่สิบเอ็ด'));
      expect(tryParseInt('๒๑'), 21);
      expect(tryParseInt('ศูนย์'), 0);
    });

    test('invalid input returns null', () {
      expect(tryParseInt('สิบสิบ'), isNull);
      expect(tryParseInt(''), isNull);
      expect(tryParseInt('ยี่ร้อย'), isNull);
    });
  });

  group('tryParseBigInt', () {
    test('valid input matches parseBigInt', () {
      expect(tryParseBigInt('หนึ่งล้านล้าน'), BigInt.from(10).pow(12));
      expect(tryParseBigInt('หนึ่งล้านล้าน'), parseBigInt('หนึ่งล้านล้าน'));
    });

    test('invalid input returns null', () {
      expect(tryParseBigInt('ร้อยพัน'), isNull);
      expect(tryParseBigInt(''), isNull);
    });
  });

  group('tryParseBaht', () {
    test('valid input matches parseBaht', () {
      expect(tryParseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'), 2121);
      expect(
        tryParseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'),
        parseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'),
      );
    });

    test('invalid input returns null', () {
      expect(tryParseBaht('สองบาทร้อยสตางค์'), isNull); // satang out of range
      expect(tryParseBaht(''), isNull);
    });
  });

  group('tryParseDate', () {
    test('valid input matches parseDate', () {
      final d = DateTime.utc(2024, 6, 5);
      expect(tryParseDate('5 มิถุนายน 2567'), d);
      expect(tryParseDate('5 มิถุนายน 2567'), parseDate('5 มิถุนายน 2567'));
    });

    test('invalid input returns null', () {
      expect(tryParseDate('not a date'), isNull);
      expect(tryParseDate(''), isNull);
    });
  });

  group('String extensions', () {
    test('tryParseThai* forward to the top-level functions', () {
      expect('ยี่สิบเอ็ด'.tryParseThaiInt(), 21);
      expect('สิบสิบ'.tryParseThaiInt(), isNull);
      expect('หนึ่งล้านล้าน'.tryParseThaiBigInt(), BigInt.from(10).pow(12));
      expect('ร้อยพัน'.tryParseThaiBigInt(), isNull);
      expect('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'.tryParseThaiBaht(), 2121);
      expect(''.tryParseThaiBaht(), isNull);
      expect('5 มิถุนายน 2567'.tryParseThaiDate(), DateTime.utc(2024, 6, 5));
      expect('not a date'.tryParseThaiDate(), isNull);
    });
  });
}
