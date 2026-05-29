// Tests for the [Baht] / [Satang] / [BahtBigInt] / [SatangBigInt] money
// wrappers. The wrappers exist so that a satang amount can never be passed
// where a baht amount is expected (and vice versa) — these tests confirm
// each wrapper's methods forward to the corresponding underlying function
// and that the wrappers' value-equality contract holds.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('Baht', () {
    test('toBahtText() spells the receiver as whole baht', () {
      expect(const Baht(100).toBahtText(), 'หนึ่งร้อยบาทถ้วน');
      expect(const Baht(100).toBahtText(), baht(100));
      expect(const Baht(21).toBahtText(), baht(21));
    });

    test('Baht and Satang produce DIFFERENT text for the same int', () {
      // 21 baht vs 21 satang — the whole reason the wrappers exist.
      expect(
        const Baht(21).toBahtText(),
        isNot(const Satang(21).toBahtText()),
      );
      expect(const Baht(21).toBahtText(), endsWith('บาทถ้วน'));
      expect(const Satang(21).toBahtText(), endsWith('สตางค์'));
    });

    test('value-equality + hashCode + toString', () {
      expect(const Baht(100), const Baht(100));
      expect(const Baht(100).hashCode, const Baht(100).hashCode);
      expect(const Baht(100), isNot(const Baht(101)));
      // Different wrapper types are distinct, even with the same numeric
      // payload — that's the type-safety guarantee.
      expect(const Baht(100), isNot(equals(const Satang(100))));
      expect(const Baht(100).toString(), 'Baht(100)');
    });

    test('usable as a Map key', () {
      final m = <Baht, String>{const Baht(100): 'a', const Baht(200): 'b'};
      expect(m[const Baht(100)], 'a');
      expect(m[const Baht(200)], 'b');
      expect(m[const Baht(300)], isNull);
    });
  });

  group('Satang', () {
    test('toBahtText() spells the receiver as satang', () {
      expect(
        const Satang(2121).toBahtText(),
        'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์',
      );
      expect(const Satang(2121).toBahtText(), bahtSatang(2121));
      expect(const Satang(25).toBahtText(), 'ยี่สิบห้าสตางค์');
    });

    test('toDecimal() and toThb()', () {
      expect(const Satang(2121).toDecimal(), '21.21');
      expect(const Satang(2121).toDecimal(), formatSatang(2121));
      expect(const Satang(2121).toThb(), '฿21.21');
      expect(const Satang(2121).toThb(), formatThb(2121));
    });

    test('value-equality + hashCode + toString', () {
      expect(const Satang(2121), const Satang(2121));
      expect(const Satang(2121).hashCode, const Satang(2121).hashCode);
      expect(const Satang(2121), isNot(const Satang(2122)));
      expect(const Satang(0).toString(), 'Satang(0)');
    });
  });

  group('BahtBigInt', () {
    test('toBahtText() forwards to bahtBigInt', () {
      final v = BigInt.from(10).pow(13); // 10 trillion baht
      expect(BahtBigInt(v).toBahtText(), bahtBigInt(v));
    });

    test('value-equality', () {
      final a = BahtBigInt(BigInt.from(123));
      final b = BahtBigInt(BigInt.from(123));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(BahtBigInt(BigInt.from(124)))));
      // Different wrapper kind, same numeric payload — still distinct.
      expect(a, isNot(equals(SatangBigInt(BigInt.from(123)))));
    });
  });

  group('SatangBigInt', () {
    test('toBahtText() forwards to bahtSatangBigInt', () {
      final v = BigInt.from(10).pow(11); // 1 billion baht in satang
      expect(SatangBigInt(v).toBahtText(), bahtSatangBigInt(v));
    });
  });
}
