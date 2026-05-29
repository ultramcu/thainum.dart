// Tests for parseDecimal (A2) and the opt-in colloquial/lenient parse flags.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('parseDecimal', () {
    test('reads integer.fraction', () {
      expect(parseDecimal('สิบสองจุดสามสี่'), '12.34');
      expect(parseDecimal('ศูนย์จุดห้า'), '0.5');
      expect(parseDecimal('หนึ่งร้อยจุดศูนย์ห้า'), '100.05');
    });

    test('negative', () {
      expect(parseDecimal('ลบสามจุดหนึ่งสี่'), '-3.14');
    });

    test('no จุด behaves like the integer string', () {
      expect(parseDecimal('ยี่สิบเอ็ด'), '21');
      expect(parseDecimal('ลบห้า'), '-5');
    });

    test('round-trips spellDecimal', () {
      expect(parseDecimal(spellDecimal('12.34')), '12.34');
      expect(parseDecimal(spellDecimal('0.5')), '0.5');
    });

    test('accepts Thai numerals in the integer part', () {
      expect(parseDecimal('๑๒จุดสามสี่'), '12.34');
    });

    group('rejects malformed input', () {
      const bad = <String>[
        'สิบสองจุด', // empty fractional run
        'สิบสองจุดสิบ', // place word in fractional part
        'จุดห้า', // missing integer part
        'หนึ่งจุดสองจุดสาม', // two จุด
        '', // empty
      ];
      for (final s in bad) {
        test('"$s" throws', () {
          expect(() => parseDecimal(s), throwsA(isA<ThaiNumException>()));
        });
      }
    });
  });

  group('allowColloquial', () {
    test('นึง reads as 1', () {
      expect(parseInt('ร้อยนึง', allowColloquial: true), 101);
      expect(parseInt('นึง', allowColloquial: true), 1);
    });

    test('strict default still rejects นึง', () {
      expect(() => parseInt('ร้อยนึง'), throwsA(isA<ThaiNumException>()));
    });

    test('flows through parseBaht', () {
      expect(parseBaht('ร้อยนึงบาทถ้วน', allowColloquial: true), 10100);
    });
  });

  group('lenient', () {
    test('strips internal spaces', () {
      expect(parseInt('ยี่สิบ เอ็ด', lenient: true), 21);
      expect(parseInt('หนึ่ง ร้อย', lenient: true), 100);
      expect(parseInt('หนึ่ง​พัน', lenient: true), 1000);
    });

    test('strict default rejects spaced input', () {
      expect(() => parseInt('ยี่สิบ เอ็ด'), throwsA(isA<ThaiNumException>()));
    });

    test('applies to parseDecimal', () {
      expect(parseDecimal('สิบสอง จุด สามสี่', lenient: true), '12.34');
    });
  });
}
