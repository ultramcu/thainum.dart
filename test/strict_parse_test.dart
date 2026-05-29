// B7: opt-in strict parse mode.
//
// Default (lenient) parsing tolerates non-standard tens forms — สองสิบ == 20,
// หนึ่งสิบ == 10 — to stay round-trip-safe. strict:true rejects them with
// ThaiNumError.nonStandardTensDigit, while canonical forms keep parsing.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('default (lenient) tens forms unchanged', () {
    test('สองสิบ == 20', () => expect(parseInt('สองสิบ'), 20));
    test('หนึ่งสิบ == 10', () => expect(parseInt('หนึ่งสิบ'), 10));
    test('สองสิบเอ็ด == 21', () => expect(parseInt('สองสิบเอ็ด'), 21));
  });

  group('strict rejects non-standard tens', () {
    test('สองสิบ throws nonStandardTensDigit', () {
      expect(
        () => parseInt('สองสิบ', strict: true),
        throwsA(isA<ThaiNumException>()
            .having((e) => e.code, 'code', ThaiNumError.nonStandardTensDigit)),
      );
    });

    test('หนึ่งสิบ throws nonStandardTensDigit', () {
      expect(
        () => parseInt('หนึ่งสิบ', strict: true),
        throwsA(isA<ThaiNumException>()
            .having((e) => e.code, 'code', ThaiNumError.nonStandardTensDigit)),
      );
    });

    test('สองสิบเอ็ด also rejected (the tens is still สอง+สิบ)', () {
      expect(() => parseInt('สองสิบเอ็ด', strict: true),
          throwsA(isA<ThaiNumException>()));
    });

    test('strict error is also a FormatException', () {
      expect(() => parseInt('สองสิบ', strict: true),
          throwsA(isA<FormatException>()));
    });
  });

  group('strict keeps canonical forms parsing', () {
    test('สิบ == 10', () => expect(parseInt('สิบ', strict: true), 10));
    test('ยี่สิบ == 20', () => expect(parseInt('ยี่สิบ', strict: true), 20));
    test('ยี่สิบเอ็ด == 21',
        () => expect(parseInt('ยี่สิบเอ็ด', strict: true), 21));
    test('สิบเอ็ด == 11', () => expect(parseInt('สิบเอ็ด', strict: true), 11));
    test('สามสิบ == 30 (3..9 over tens is standard)',
        () => expect(parseInt('สามสิบ', strict: true), 30));
    test('ห้าสิบห้า == 55',
        () => expect(parseInt('ห้าสิบห้า', strict: true), 55));
    test('higher places with digit-1 are fine (หนึ่งร้อย == 100)',
        () => expect(parseInt('หนึ่งร้อย', strict: true), 100));
    test('หนึ่งล้าน == 1000000',
        () => expect(parseInt('หนึ่งล้าน', strict: true), 1000000));
    test('ร้อยสิบ == 110 (bare สิบ, not fed by a digit)',
        () => expect(parseInt('ร้อยสิบ', strict: true), 110));
  });

  group('strict flows through the other parsers', () {
    test('parseBigInt strict rejects สองสิบ', () {
      expect(() => parseBigInt('สองสิบ', strict: true),
          throwsA(isA<ThaiNumException>()));
    });
    test('parseBigInt strict accepts ยี่สิบ',
        () => expect(parseBigInt('ยี่สิบ', strict: true), BigInt.from(20)));

    test('parseBaht strict rejects สองสิบบาท', () {
      expect(() => parseBaht('สองสิบบาท', strict: true),
          throwsA(isA<ThaiNumException>()));
    });
    test('parseBaht strict accepts ยี่สิบบาทถ้วน',
        () => expect(parseBaht('ยี่สิบบาทถ้วน', strict: true), 2000));
    test('parseBaht strict rejects bad satang form', () {
      expect(() => parseBaht('สิบบาทสองสิบสตางค์', strict: true),
          throwsA(isA<ThaiNumException>()));
    });

    test('parseDecimal strict rejects สองสิบจุดห้า', () {
      expect(() => parseDecimal('สองสิบจุดห้า', strict: true),
          throwsA(isA<ThaiNumException>()));
    });
    test('parseDecimal strict accepts ยี่สิบจุดห้า',
        () => expect(parseDecimal('ยี่สิบจุดห้า', strict: true), '20.5'));
  });

  group('strict default-off matches lenient default everywhere', () {
    const samples = [
      'สิบ',
      'ยี่สิบ',
      'ยี่สิบเอ็ด',
      'สามสิบ',
      'หนึ่งร้อย',
      'หนึ่งล้าน',
      'สองสิบ', // non-standard but accepted by default
      'หนึ่งสิบ',
    ];
    for (final s in samples) {
      test('"$s": strict:false == bare call', () {
        expect(parseInt(s, strict: false), parseInt(s));
      });
    }
  });
}
