// Direct coverage for the core spelling primitives (A7). Hand-checked Thai
// readings at the boundaries that exercise the group/place/ล้าน machinery.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('spell — boundaries (default EtMode.always)', () {
    const cases = <int, String>{
      0: 'ศูนย์',
      11: 'สิบเอ็ด',
      20: 'ยี่สิบ',
      21: 'ยี่สิบเอ็ด',
      101: 'หนึ่งร้อยเอ็ด',
      1001: 'หนึ่งพันเอ็ด',
      1000000: 'หนึ่งล้าน',
    };
    cases.forEach((n, want) {
      test('spell($n) == $want', () => expect(spell(n), want));
    });

    test('negatives', () {
      expect(spell(-21), 'ลบยี่สิบเอ็ด');
      expect(spell(-1000000), 'ลบหนึ่งล้าน');
    });
  });

  group('spell — EtMode.tensOnly', () {
    const speller = Speller(et: EtMode.tensOnly);
    test('101 reads หนึ่ง not เอ็ด at the units', () {
      expect(speller.spellInt(101), 'หนึ่งร้อยหนึ่ง');
      expect(speller.spellInt(1001), 'หนึ่งพันหนึ่ง');
    });

    test('11/21 still use เอ็ด (tens non-zero)', () {
      expect(speller.spellInt(11), 'สิบเอ็ด');
      expect(speller.spellInt(21), 'ยี่สิบเอ็ด');
    });

    test('1000001 trailing lone 1 reads หนึ่ง', () {
      expect(speller.spellInt(1000001), 'หนึ่งล้านหนึ่ง');
    });
  });

  group('spellBigInt — stacked ล้าน', () {
    test('10^6, 10^12', () {
      expect(spellBigInt(BigInt.from(1000000)), 'หนึ่งล้าน');
      expect(spellBigInt(BigInt.from(10).pow(12)), 'หนึ่งล้านล้าน');
    });

    test('1000001 via BigInt uses เอ็ด by default', () {
      expect(spellBigInt(BigInt.from(1000001)), 'หนึ่งล้านเอ็ด');
    });

    test('negative BigInt', () {
      expect(spellBigInt(BigInt.from(-1000000)), 'ลบหนึ่งล้าน');
    });
  });

  group('spellDecimal', () {
    test('reads จุด + per-digit fraction', () {
      expect(spellDecimal('12.34'), 'สิบสองจุดสามสี่');
      expect(spellDecimal('0.5'), 'ศูนย์จุดห้า');
    });

    test('drops all-zero fraction', () {
      expect(spellDecimal('100.00'), 'หนึ่งร้อย');
    });

    test('negative', () {
      expect(spellDecimal('-3.14'), 'ลบสามจุดหนึ่งสี่');
    });
  });
}
