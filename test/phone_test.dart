// Tests for Thai phone formatting + spoken reading (B10).

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('formatThaiPhone', () {
    test('mobile 3-3-4 grouping', () {
      expect(formatThaiPhone('0812345678'), '081-234-5678');
    });

    test('strips existing separators and spaces', () {
      expect(formatThaiPhone('081 234 5678'), '081-234-5678');
      expect(formatThaiPhone('081-234-5678'), '081-234-5678');
      expect(formatThaiPhone('(081) 234-5678'), '081-234-5678');
    });

    test('accepts Thai numerals', () {
      expect(formatThaiPhone('๐๘๑๒๓๔๕๖๗๘'), '081-234-5678');
    });

    test('landline 2-3-4 grouping (best-effort)', () {
      expect(formatThaiPhone('021234567'), '02-123-4567');
    });

    test('accepts +66 country code', () {
      expect(formatThaiPhone('+66812345678'), '081-234-5678');
    });

    test('unrecognised length is returned as bare digits', () {
      expect(formatThaiPhone('1234'), '1234');
    });

    test('toll-free 1800 is not mis-grouped as mobile', () {
      // 10 digits long, but classified tollFree → bare digits, not 3-3-4.
      expect(formatThaiPhone('1800123456'), '1800123456');
    });

    test('short code is returned as bare digits', () {
      expect(formatThaiPhone('1669'), '1669');
      expect(formatThaiPhone('191'), '191');
    });

    test('no-digit input is returned unchanged', () {
      expect(formatThaiPhone('abc'), 'abc');
      expect(formatThaiPhone(''), '');
    });
  });

  group('thaiPhoneKind', () {
    test('mobile prefixes 06/08/09', () {
      expect(thaiPhoneKind('0612345678'), ThaiPhoneKind.mobile);
      expect(thaiPhoneKind('0812345678'), ThaiPhoneKind.mobile);
      expect(thaiPhoneKind('0912345678'), ThaiPhoneKind.mobile);
    });

    test('10-digit 0 + non-mobile second digit is unknown', () {
      expect(thaiPhoneKind('0712345678'), ThaiPhoneKind.unknown);
    });

    test('Bangkok landline 02 + 9 digits', () {
      expect(thaiPhoneKind('021234567'), ThaiPhoneKind.landline);
    });

    test('provincial landline 0X + 9 digits', () {
      expect(thaiPhoneKind('053123456'), ThaiPhoneKind.landline);
    });

    test('toll-free 1800', () {
      expect(thaiPhoneKind('1800123456'), ThaiPhoneKind.tollFree);
    });

    test('short codes', () {
      expect(thaiPhoneKind('191'), ThaiPhoneKind.shortCode);
      expect(thaiPhoneKind('1669'), ThaiPhoneKind.shortCode);
    });

    test('+66 mobile classifies as mobile', () {
      expect(thaiPhoneKind('+66812345678'), ThaiPhoneKind.mobile);
    });

    test('unknown when unsure', () {
      expect(thaiPhoneKind('12345'), ThaiPhoneKind.unknown);
      expect(thaiPhoneKind(''), ThaiPhoneKind.unknown);
      expect(thaiPhoneKind('abc'), ThaiPhoneKind.unknown);
    });
  });

  group('normalizeThaiPhone', () {
    test('drops leading 0, prefixes +66', () {
      expect(normalizeThaiPhone('0812345678'), '+66812345678');
    });

    test('landline normalises too', () {
      // 9 national digits → 8 after dropping the trunk 0, prefixed +66.
      expect(normalizeThaiPhone('02-123-4567'), '+6621234567');
    });

    test('is idempotent on +66 input', () {
      expect(normalizeThaiPhone('+66812345678'), '+66812345678');
    });

    test('accepts Thai numerals and separators', () {
      expect(normalizeThaiPhone('๐๘๑-๒๓๔-๕๖๗๘'), '+66812345678');
    });

    test('throws when no digits', () {
      expect(() => normalizeThaiPhone('---'), throwsFormatException);
    });
  });

  group('speakThaiPhone', () {
    test('reads digit-by-digit', () {
      expect(speakThaiPhone('0812345678'),
          'ศูนย์ แปด หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด');
    });

    test('colloquialTwo reads 2 as โท', () {
      expect(speakThaiPhone('0812345678', colloquialTwo: true),
          'ศูนย์ แปด หนึ่ง โท สาม สี่ ห้า หก เจ็ด แปด');
    });

    test('+66 reads the same as the national form', () {
      expect(speakThaiPhone('+66812345678'), speakThaiPhone('0812345678'));
    });
  });

  group('String extensions', () {
    test('formatThaiPhone / thaiPhoneKind / normalize / speak', () {
      expect('0812345678'.formatThaiPhone(), '081-234-5678');
      expect('0812345678'.thaiPhoneKind(), ThaiPhoneKind.mobile);
      expect('0812345678'.normalizeThaiPhone(), '+66812345678');
      expect('0812345678'.speakThaiPhone(),
          'ศูนย์ แปด หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด');
    });
  });
}
