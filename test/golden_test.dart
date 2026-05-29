// Hand-checked golden table of (int, Thai reading) pairs. This guards against
// a *mutual* spell↔parse bug that a round-trip test cannot catch (a round-trip
// passes even if both directions share the same wrong convention). Every entry
// here is asserted by hand against standard Thai number reading and uses the
// default EtMode (EtMode.always).

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('spell golden table (default EtMode.always)', () {
    const cases = <int, String>{
      0: 'ศูนย์',
      1: 'หนึ่ง',
      2: 'สอง',
      5: 'ห้า',
      10: 'สิบ',
      11: 'สิบเอ็ด',
      12: 'สิบสอง',
      20: 'ยี่สิบ',
      21: 'ยี่สิบเอ็ด',
      100: 'หนึ่งร้อย',
      101: 'หนึ่งร้อยเอ็ด',
      111: 'หนึ่งร้อยสิบเอ็ด',
      1000: 'หนึ่งพัน',
      1001: 'หนึ่งพันเอ็ด',
      11111: 'หนึ่งหมื่นหนึ่งพันหนึ่งร้อยสิบเอ็ด',
      100000: 'หนึ่งแสน',
      1000000: 'หนึ่งล้าน',
      1000001: 'หนึ่งล้านเอ็ด',
      2000000: 'สองล้าน',
    };
    cases.forEach((n, want) {
      test('spell($n) == $want', () {
        expect(spell(n), want);
      });
    });

    test('negatives prefix ลบ', () {
      expect(spell(-5), 'ลบห้า');
      expect(spell(-21), 'ลบยี่สิบเอ็ด');
    });
  });

  group('spellBigInt golden table', () {
    final cases = <BigInt, String>{
      BigInt.from(1000000): 'หนึ่งล้าน',
      BigInt.from(10).pow(12): 'หนึ่งล้านล้าน',
      BigInt.from(10).pow(18): 'หนึ่งล้านล้านล้าน',
      BigInt.parse('2000000000000'): 'สองล้านล้าน',
    };
    cases.forEach((n, want) {
      test('spellBigInt($n) == $want', () {
        expect(spellBigInt(n), want);
      });
    });
  });
}
