// Coverage for A5 abbreviated large-number reading: spellShort / formatShort
// (and the BigInt forms + extensions). Hand-checked Thai readings at the unit
// boundaries, the rounding-carry case, decimals 0/3, trailing-zero trimming,
// negatives, the < 10^6 fallback, and the thaiDigits flag.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('spellShort — worked examples (decimals 2 default)', () {
    const cases = <int, String>{
      1500000: 'หนึ่งจุดห้าล้าน',
      15000000: 'สิบห้าล้าน',
      2300000000: 'สองจุดสามพันล้าน',
      50000000000: 'ห้าสิบพันล้าน',
      1200000000000: 'หนึ่งจุดสองล้านล้าน',
      1234567: 'หนึ่งจุดสองสามล้าน',
    };
    cases.forEach((n, want) {
      test('spellShort($n) == $want', () => expect(spellShort(n), want));
    });
  });

  group('formatShort — worked examples (decimals 2 default)', () {
    const cases = <int, String>{
      1500000: '1.5 ล้าน',
      15000000: '15 ล้าน',
      2300000000: '2.3 พันล้าน',
      50000000000: '50 พันล้าน',
      1200000000000: '1.2 ล้านล้าน',
      1234567: '1.23 ล้าน',
    };
    cases.forEach((n, want) {
      test('formatShort($n) == $want', () => expect(formatShort(n), want));
    });
  });

  group('unit-name generation', () {
    test('10^6 .. 10^18 (int range)', () {
      expect(formatShort(1000000), '1 ล้าน');
      expect(formatShort(1000000000), '1 พันล้าน');
      expect(formatShort(1000000000000), '1 ล้านล้าน');
      expect(formatShort(1000000000000000), '1 พันล้านล้าน');
      expect(formatShort(1000000000000000000), '1 ล้านล้านล้าน');
    });

    test('10^6 .. 10^18 spelled', () {
      expect(spellShort(1000000), 'หนึ่งล้าน');
      expect(spellShort(1000000000), 'หนึ่งพันล้าน');
      expect(spellShort(1000000000000), 'หนึ่งล้านล้าน');
      expect(spellShort(1000000000000000), 'หนึ่งพันล้านล้าน');
      expect(spellShort(1000000000000000000), 'หนึ่งล้านล้านล้าน');
    });

    test('BigInt 10^21 / 10^24', () {
      expect(formatShortBigInt(BigInt.parse('1000000000000000000000')),
          '1 พันล้านล้านล้าน');
      expect(formatShortBigInt(BigInt.parse('1000000000000000000000000')),
          '1 ล้านล้านล้านล้าน');
      expect(spellShortBigInt(BigInt.parse('1000000000000000000000')),
          'หนึ่งพันล้านล้านล้าน');
      expect(spellShortBigInt(BigInt.parse('1000000000000000000000000')),
          'หนึ่งล้านล้านล้านล้าน');
    });
  });

  group('coefficient boundaries', () {
    test('just below the next unit stays in the lower unit', () {
      // 999,000,000 < 10^9 → ล้าน unit, coefficient 999.
      expect(formatShort(999000000), '999 ล้าน');
      expect(spellShort(999000000), 'เก้าร้อยเก้าสิบเก้าล้าน');
    });

    test('exact unit → whole coefficient, no จุด', () {
      expect(spellShort(2000000), 'สองล้าน');
      expect(formatShort(2000000), '2 ล้าน');
    });

    test('rounding carry 999,999,999 → 1 พันล้าน', () {
      // ≈ 1000.00 ล้าน rounds up and promotes to the next unit.
      expect(formatShort(999999999), '1 พันล้าน');
      expect(spellShort(999999999), 'หนึ่งพันล้าน');
    });
  });

  group('decimals parameter', () {
    test('decimals 0 rounds to a whole coefficient', () {
      expect(formatShort(1500000, decimals: 0), '2 ล้าน');
      expect(formatShort(1234567, decimals: 0), '1 ล้าน');
      expect(spellShort(1500000, decimals: 0), 'สองล้าน');
    });

    test('decimals 3 keeps more precision', () {
      expect(formatShort(1234567, decimals: 3), '1.235 ล้าน');
      expect(spellShort(1234567, decimals: 3), 'หนึ่งจุดสองสามห้าล้าน');
    });

    test('negative decimals throws ArgumentError', () {
      expect(() => spellShort(1500000, decimals: -1), throwsArgumentError);
      expect(() => formatShort(1500000, decimals: -1), throwsArgumentError);
    });
  });

  group('trailing-zero trimming', () {
    test('2,000,000 trims to a whole coefficient', () {
      expect(spellShort(2000000), 'สองล้าน');
      expect(formatShort(2000000), '2 ล้าน');
    });

    test('one significant fractional digit', () {
      expect(formatShort(2500000), '2.5 ล้าน');
      expect(spellShort(2500000), 'สองจุดห้าล้าน');
    });
  });

  group('negative', () {
    test('spellShort prefixes ลบ', () {
      expect(spellShort(-1500000), 'ลบหนึ่งจุดห้าล้าน');
      expect(spellShort(-15000000), 'ลบสิบห้าล้าน');
    });

    test('formatShort prefixes -', () {
      expect(formatShort(-1500000), '-1.5 ล้าน');
      expect(formatShort(-50000000000), '-50 พันล้าน');
    });
  });

  group('< 10^6 fallback equals the full reading', () {
    const samples = <int>[0, 5, 999, 1000, 12345, 999999, -999999, -1];
    for (final n in samples) {
      test('spellShort($n) == spell($n)', () {
        expect(spellShort(n), spell(n));
      });
      test('formatShort($n) == formatInt($n)', () {
        expect(formatShort(n), formatInt(n));
      });
    }

    test('999999 fallback golden', () {
      expect(spellShort(999999), spell(999999));
      expect(formatShort(999999), '999,999');
    });
  });

  group('thaiDigits flag', () {
    test('only the coefficient digits become Thai numerals', () {
      expect(formatShort(1500000, thaiDigits: true), '๑.๕ ล้าน');
      expect(formatShort(15000000, thaiDigits: true), '๑๕ ล้าน');
      expect(formatShort(2300000000, thaiDigits: true), '๒.๓ พันล้าน');
    });

    test('negative with thaiDigits keeps ASCII sign and point', () {
      expect(formatShort(-1500000, thaiDigits: true), '-๑.๕ ล้าน');
    });
  });

  group('extensions', () {
    test('int.toThaiShortWords / toShortString', () {
      expect(1500000.toThaiShortWords(), 'หนึ่งจุดห้าล้าน');
      expect(1500000.toShortString(), '1.5 ล้าน');
      expect(1234567.toShortString(decimals: 0), '1 ล้าน');
      expect(1500000.toShortString(thaiDigits: true), '๑.๕ ล้าน');
    });

    test('BigInt.toThaiShortWords / toShortString', () {
      expect(BigInt.parse('1200000000000').toThaiShortWords(),
          'หนึ่งจุดสองล้านล้าน');
      expect(BigInt.parse('1200000000000').toShortString(), '1.2 ล้านล้าน');
    });
  });

  group('BigInt-scale goldens (beyond int range)', () {
    test('non-pure-power coefficient at 10^18 scale', () {
      // 1.234×10^18 → ล้านล้านล้าน unit, coefficient 1.23 (decimals=2).
      final v = BigInt.parse('1234000000000000000');
      expect(spellShortBigInt(v), 'หนึ่งจุดสองสามล้านล้านล้าน');
      expect(formatShortBigInt(v), '1.23 ล้านล้านล้าน');
    });

    test('rounding carry promotes one unit at BigInt scale', () {
      // 999,999,999,999,999,999 (≈10^18): largest unit ≤ it is 10^15
      // (พันล้านล้าน), coefficient ≈ 999.9999… → rounds up to 1000.00 →
      // promotes to 10^18 (ล้านล้านล้าน) with coefficient 1.
      final v = BigInt.parse('999999999999999999');
      expect(spellShortBigInt(v), 'หนึ่งล้านล้านล้าน');
      expect(formatShortBigInt(v), '1 ล้านล้านล้าน');
    });
  });

  group('int / BigInt agree on the shared impl', () {
    const samples = <int>[
      1500000,
      15000000,
      2300000000,
      50000000000,
      999999999,
      1234567,
    ];
    for (final n in samples) {
      test('spellShort($n) matches BigInt form', () {
        expect(spellShort(n), spellShortBigInt(BigInt.from(n)));
        expect(formatShort(n), formatShortBigInt(BigInt.from(n)));
      });
    }
  });
}
