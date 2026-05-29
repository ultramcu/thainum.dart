// Tests for the additive `thaiDigits:` flag (S3) on the formatters and date
// helpers. The flag converts ONLY ASCII digits to Thai numerals; commas, the
// decimal point, the ฿ symbol, the `-` sign and labels like พ.ศ. stay ASCII.
// Critically, the default (thaiDigits: false) output must be byte-identical to
// the pre-existing function output.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  final wed = DateTime.utc(2024, 6, 5); // Wednesday, BE 2567

  group('formatters with thaiDigits: true', () {
    test('formatInt converts only the digits', () {
      expect(formatInt(1234567, thaiDigits: true), '๑,๒๓๔,๕๖๗');
      expect(formatInt(-1500, thaiDigits: true), '-๑,๕๐๐'); // sign stays ASCII
    });

    test('formatSatang keeps . and , ASCII', () {
      expect(formatSatang(2121, thaiDigits: true), '๒๑.๒๑');
      expect(formatSatang(100000, thaiDigits: true), '๑,๐๐๐.๐๐');
    });

    test('formatThb keeps the ฿ symbol ASCII', () {
      expect(formatThb(2121, thaiDigits: true), '฿๒๑.๒๑');
      expect(formatThb(-2121, thaiDigits: true), '-฿๒๑.๒๑');
    });

    test('date formatters keep month/label text, convert digits', () {
      expect(formatDate(wed, thaiDigits: true), '๕ มิถุนายน ๒๕๖๗');
      expect(formatDateAbbr(wed, thaiDigits: true), '๕ มิ.ย. ๒๕๖๗');
      expect(
        formatDateFull(wed, thaiDigits: true),
        'วันพุธที่ ๕ มิถุนายน พ.ศ. ๒๕๖๗',
      );
    });

    test('extension methods forward the flag', () {
      expect(1234567.toThousandsString(thaiDigits: true), '๑,๒๓๔,๕๖๗');
      expect(const Satang(2121).toDecimal(thaiDigits: true), '๒๑.๒๑');
      expect(const Satang(2121).toThb(thaiDigits: true), '฿๒๑.๒๑');
      expect(wed.toThaiDate(thaiDigits: true), '๕ มิถุนายน ๒๕๖๗');
      expect(wed.toThaiDateAbbr(thaiDigits: true), '๕ มิ.ย. ๒๕๖๗');
      expect(
        wed.toThaiDateFull(thaiDigits: true),
        'วันพุธที่ ๕ มิถุนายน พ.ศ. ๒๕๖๗',
      );
    });
  });

  group('default (thaiDigits: false) is byte-identical to existing output', () {
    test('formatters', () {
      expect(formatInt(1234567), '1,234,567');
      expect(formatInt(1234567, thaiDigits: false), formatInt(1234567));
      expect(formatSatang(2121, thaiDigits: false), formatSatang(2121));
      expect(formatSatang(2121), '21.21');
      expect(formatThb(2121, thaiDigits: false), formatThb(2121));
      expect(formatThb(2121), '฿21.21');
      expect(formatThb(-2121, thaiDigits: false), formatThb(-2121));
    });

    test('date helpers', () {
      expect(formatDate(wed, thaiDigits: false), formatDate(wed));
      expect(formatDate(wed), '5 มิถุนายน 2567');
      expect(formatDateAbbr(wed, thaiDigits: false), formatDateAbbr(wed));
      expect(formatDateFull(wed, thaiDigits: false), formatDateFull(wed));
      expect(formatDateFull(wed), 'วันพุธที่ 5 มิถุนายน พ.ศ. 2567');
    });

    test('extension methods', () {
      expect(
        1234567.toThousandsString(thaiDigits: false),
        1234567.toThousandsString(),
      );
      expect(const Satang(2121).toDecimal(thaiDigits: false), '21.21');
      expect(const Satang(2121).toThb(thaiDigits: false), '฿21.21');
      expect(wed.toThaiDate(thaiDigits: false), wed.toThaiDate());
      expect(wed.toThaiDateAbbr(thaiDigits: false), wed.toThaiDateAbbr());
      expect(wed.toThaiDateFull(thaiDigits: false), wed.toThaiDateFull());
    });
  });
}
