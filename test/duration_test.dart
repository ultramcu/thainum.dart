// Direct coverage for formatDuration (A7).

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('formatDuration', () {
    test('zero reads ศูนย์วินาที', () {
      expect(formatDuration(Duration.zero), 'ศูนย์วินาที');
    });

    test('seconds only', () {
      expect(formatDuration(const Duration(seconds: 45)), 'สี่สิบห้าวินาที');
    });

    test('90 minutes → 1h 30m', () {
      expect(
        formatDuration(const Duration(minutes: 90)),
        'หนึ่งชั่วโมงสามสิบนาที',
      );
    });

    test('days + hours', () {
      expect(
        formatDuration(const Duration(days: 2, hours: 3)),
        'สองวันสามชั่วโมง',
      );
    });

    test('negative is prefixed ลบ', () {
      expect(
        formatDuration(const Duration(minutes: -90)),
        'ลบหนึ่งชั่วโมงสามสิบนาที',
      );
    });
  });
}
