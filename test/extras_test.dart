// Direct coverage for ordinal / fraction / year / CE-BE helpers (A7).

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('ordinal', () {
    test('prefixes ที่', () {
      expect(ordinal(1), 'ที่หนึ่ง');
      expect(ordinal(21), 'ที่ยี่สิบเอ็ด');
    });
  });

  group('fraction', () {
    test('เศษ … ส่วน …', () {
      expect(fraction(1, 2), 'เศษหนึ่งส่วนสอง');
      expect(fraction(3, 4), 'เศษสามส่วนสี่');
    });
  });

  group('year (BE)', () {
    test('พุทธศักราช + spelled year', () {
      expect(year(2566), 'พุทธศักราชสองพันห้าร้อยหกสิบหก');
    });
  });

  group('ceToBe / beToCe', () {
    test('+543 / -543 round-trip', () {
      expect(ceToBe(2026), 2569);
      expect(beToCe(2569), 2026);
      expect(beToCe(ceToBe(2024)), 2024);
    });
  });
}
