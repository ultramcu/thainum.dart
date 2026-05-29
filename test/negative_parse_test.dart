// Data-driven negative tests: each input must throw a ThaiNumException (which
// is also a FormatException). The chosen inputs were verified against the
// current parser to actually throw before being locked in here.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('parseInt rejects malformed words', () {
    const bad = <String>[
      'สิบสิบ', // repeated place
      'ร้อยพัน', // ascending places
      'เอ็ดสิบ', // เอ็ด cannot precede a place word
      'ยี่ร้อย', // ยี่ must be followed by สิบ
      '', // empty
    ];
    for (final s in bad) {
      test('"$s" throws', () {
        expect(() => parseInt(s), throwsA(isA<ThaiNumException>()));
        expect(() => parseInt(s), throwsA(isA<FormatException>()));
      });
    }
  });

  group('parseBaht rejects out-of-range satang', () {
    test('"สองบาทร้อยสตางค์" (satang 100) throws', () {
      // 100 satang is out of the 0..99 range.
      expect(
        () => parseBaht('สองบาทร้อยสตางค์'),
        throwsA(isA<ThaiNumException>()),
      );
      expect(
        () => parseBaht('สองบาทร้อยสตางค์'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
