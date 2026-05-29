// Tests for speakDigits (S2) — digit-by-digit reading (อ่านเรียงตัว).

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('speakDigits', () {
    test('reads each digit individually, not as a quantity', () {
      expect(speakDigits('2566'), 'สอง ห้า หก หก');
      expect(speakDigits('0'), 'ศูนย์');
      expect(speakDigits('9'), 'เก้า');
    });

    test('accepts Thai numerals as well as Arabic', () {
      expect(speakDigits('๒๕๖๖'), 'สอง ห้า หก หก');
      expect(speakDigits('๒566'), speakDigits('2566'));
    });

    test('non-digits collapse to a single separator, no leading/trailing', () {
      const expected = 'ศูนย์ แปด หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด';
      expect(speakDigits('081-234-5678'), expected);
      expect(speakDigits('0812345678'), expected);
      expect(speakDigits('  081 234 5678  '), expected);
    });

    test('empty / no-digit input returns empty string', () {
      expect(speakDigits(''), '');
      expect(speakDigits('abc'), '');
      expect(speakDigits('---'), '');
    });

    test('custom separator', () {
      expect(speakDigits('2566', separator: '-'), 'สอง-ห้า-หก-หก');
      expect(speakDigits('12', separator: ''), 'หนึ่งสอง');
    });

    test('colloquialTwo renders 2 as โท', () {
      expect(speakDigits('2566', colloquialTwo: true), 'โท ห้า หก หก');
      expect(speakDigits('22', colloquialTwo: true), 'โท โท');
      // Other digits unchanged.
      expect(speakDigits('123', colloquialTwo: true), 'หนึ่ง โท สาม');
      // Default leaves 2 as สอง.
      expect(speakDigits('2'), 'สอง');
    });
  });

  group('String extension speakThaiDigits', () {
    test('forwards to speakDigits with the same options', () {
      expect('2566'.speakThaiDigits(), 'สอง ห้า หก หก');
      expect('2566'.speakThaiDigits(), speakDigits('2566'));
      expect(
        '2566'.speakThaiDigits(colloquialTwo: true),
        speakDigits('2566', colloquialTwo: true),
      );
      expect(
        '2566'.speakThaiDigits(separator: '-'),
        speakDigits('2566', separator: '-'),
      );
    });
  });
}
