// Tests for percent reading & formatting (A4). Hand-checked Thai readings.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('percent — royalRoiLa (default)', () {
    test('integer', () {
      expect(percent(25), 'ร้อยละยี่สิบห้า');
      expect(percent(100), 'ร้อยละหนึ่งร้อย');
      expect(percent(0), 'ร้อยละศูนย์');
    });

    test('decimal', () {
      expect(percent(25.5), 'ร้อยละยี่สิบห้าจุดห้า');
      expect(percent(0.5), 'ร้อยละศูนย์จุดห้า');
    });

    test('whole double reads as integer', () {
      expect(percent(25.0), 'ร้อยละยี่สิบห้า');
    });

    test('negative', () {
      expect(percent(-5), 'ร้อยละลบห้า');
    });
  });

  group('percent — colloquialPercent', () {
    test('integer suffix', () {
      expect(
        percent(25, style: PercentStyle.colloquialPercent),
        'ยี่สิบห้าเปอร์เซ็นต์',
      );
    });

    test('decimal suffix', () {
      expect(
        percent(25.5, style: PercentStyle.colloquialPercent),
        'ยี่สิบห้าจุดห้าเปอร์เซ็นต์',
      );
    });
  });

  group('formatPercent', () {
    test('integer', () {
      expect(formatPercent(25), '25%');
      expect(formatPercent(0), '0%');
    });

    test('fractional trims trailing zeros', () {
      expect(formatPercent(25.5), '25.5%');
      expect(formatPercent(25.0), '25%');
      expect(formatPercent(25.50), '25.5%');
    });
  });

  group('num.toThaiPercent() extension', () {
    test('forwards to percent()', () {
      expect(25.toThaiPercent(), percent(25));
      expect(25.5.toThaiPercent(), percent(25.5));
      expect(
        25.toThaiPercent(style: PercentStyle.colloquialPercent),
        'ยี่สิบห้าเปอร์เซ็นต์',
      );
    });
  });
}
