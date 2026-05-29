import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('spellDecimal useHalf:false regression (byte-identical)', () {
    // These must be exactly what the classic จุด reader produces.
    final cases = {
      '2.5': 'สองจุดห้า',
      '0.5': 'ศูนย์จุดห้า',
      '10.5': 'สิบจุดห้า',
      '12.34': 'สิบสองจุดสามสี่',
      '100.00': 'หนึ่งร้อย',
      '2.25': 'สองจุดสองห้า',
      '0.05': 'ศูนย์จุดศูนย์ห้า',
      '21': 'ยี่สิบเอ็ด',
    };
    cases.forEach((input, expected) {
      test('$input (default)', () {
        expect(spellDecimal(input), expected);
        // Explicit false must equal the default.
        expect(spellDecimal(input, useHalf: false), expected);
      });
    });
  });

  group('spellDecimal useHalf:true', () {
    test('exact half cases use ครึ่ง', () {
      expect(spellDecimal('2.5', useHalf: true), 'สองครึ่ง');
      expect(spellDecimal('0.5', useHalf: true), 'ครึ่ง');
      expect(spellDecimal('10.5', useHalf: true), 'สิบครึ่ง');
      expect(spellDecimal('100.5', useHalf: true), 'หนึ่งร้อยครึ่ง');
      // Trailing zeros still count as an exact half.
      expect(spellDecimal('2.50', useHalf: true), 'สองครึ่ง');
      expect(spellDecimal('2.500', useHalf: true), 'สองครึ่ง');
    });

    test('negative exact half', () {
      expect(spellDecimal('-2.5', useHalf: true), 'ลบสองครึ่ง');
      expect(spellDecimal('-0.5', useHalf: true), 'ลบครึ่ง');
    });

    test('non-.5 fractions still read digit-by-digit', () {
      expect(spellDecimal('2.25', useHalf: true), 'สองจุดสองห้า');
      expect(spellDecimal('2.55', useHalf: true), 'สองจุดห้าห้า');
      expect(spellDecimal('2.51', useHalf: true), 'สองจุดห้าหนึ่ง');
      expect(spellDecimal('0.05', useHalf: true), 'ศูนย์จุดศูนย์ห้า');
    });

    test('integers and all-zero fractions unaffected', () {
      expect(spellDecimal('100.00', useHalf: true), 'หนึ่งร้อย');
      expect(spellDecimal('21', useHalf: true), 'ยี่สิบเอ็ด');
    });
  });

  group('unit words', () {
    test('quantityWord / quantityValue', () {
      expect(quantityWord(QuantityUnit.dozen), 'โหล');
      expect(quantityWord(QuantityUnit.gross), 'กุรุส');
      expect(quantityValue(QuantityUnit.half), 0.5);
      expect(quantityValue(QuantityUnit.pair), 2);
      expect(quantityValue(QuantityUnit.dozen), 12);
      expect(quantityValue(QuantityUnit.gross), 144);
    });
  });

  group('parseQuantity', () {
    test('standalone unit words', () {
      expect(parseQuantity('ครึ่ง'), 0.5);
      expect(parseQuantity('คู่'), 2);
      expect(parseQuantity('โหล'), 12);
      expect(parseQuantity('กุรุส'), 144);
    });

    test('integer + trailing ครึ่ง', () {
      expect(parseQuantity('สองครึ่ง'), 2.5);
      expect(parseQuantity('สิบครึ่ง'), 10.5);
      expect(parseQuantity('หนึ่งร้อยครึ่ง'), 100.5);
    });

    test('plain integer reading', () {
      expect(parseQuantity('สอง'), 2);
      expect(parseQuantity('ยี่สิบเอ็ด'), 21);
      expect(parseQuantity('๑๒'), 12); // Thai digits
    });

    test('round-trip with spellDecimal useHalf', () {
      for (final n in [2.5, 10.5, 100.5]) {
        final words = spellDecimal(n.toString(), useHalf: true);
        expect(parseQuantity(words), n, reason: words);
      }
    });

    test('malformed throws', () {
      expect(() => parseQuantity(''), throwsA(isA<ThaiNumException>()));
      expect(
          () => parseQuantity('ไม่ใช่เลข'), throwsA(isA<ThaiNumException>()));
      // Double ครึ่ง is rejected.
      expect(
          () => parseQuantity('ครึ่งครึ่ง'), throwsA(isA<ThaiNumException>()));
    });

    test('returns int when whole, double when half', () {
      expect(parseQuantity('โหล'), isA<int>());
      expect(parseQuantity('สอง'), isA<int>());
      expect(parseQuantity('สองครึ่ง'), isA<double>());
      expect(parseQuantity('ครึ่ง'), isA<double>());
    });
  });

  group('parseHalfBaht', () {
    test('ครึ่งบาท -> 50 satang', () {
      expect(parseHalfBaht('ครึ่งบาท'), 50);
      expect(parseHalfBaht('  ครึ่งบาท  '), 50);
    });
    test('anything else throws', () {
      expect(() => parseHalfBaht('หนึ่งบาท'), throwsA(isA<ThaiNumException>()));
      expect(() => parseHalfBaht('ครึ่ง'), throwsA(isA<ThaiNumException>()));
      expect(() => parseHalfBaht(''), throwsA(isA<ThaiNumException>()));
    });
  });
}
