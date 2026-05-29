// Direct coverage for the Thai date formatters and the format⇄parse round-trip
// (A7), in both Arabic and Thai digits.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  final d = DateTime.utc(2024, 6, 5); // Wednesday

  group('formatDate / Abbr / Full', () {
    test('Arabic digits', () {
      expect(formatDate(d), '5 มิถุนายน 2567');
      expect(formatDateAbbr(d), '5 มิ.ย. 2567');
      expect(formatDateFull(d), 'วันพุธที่ 5 มิถุนายน พ.ศ. 2567');
    });

    test('Thai digits', () {
      expect(formatDate(d, thaiDigits: true), '๕ มิถุนายน ๒๕๖๗');
      expect(formatDateAbbr(d, thaiDigits: true), '๕ มิ.ย. ๒๕๖๗');
      expect(formatDateFull(d, thaiDigits: true),
          'วันพุธที่ ๕ มิถุนายน พ.ศ. ๒๕๖๗');
    });
  });

  group('formatDate ⇄ parseDate round-trip', () {
    final dates = <DateTime>[
      DateTime.utc(2024, 1, 1),
      DateTime.utc(2024, 6, 5),
      DateTime.utc(1999, 12, 31),
      DateTime.utc(2026, 5, 29),
    ];
    for (final dt in dates) {
      test('Arabic $dt', () {
        expect(parseDate(formatDate(dt)), dt);
        expect(parseDate(formatDateAbbr(dt)), dt);
        expect(parseDate(formatDateFull(dt)), dt);
      });
      test('Thai digits $dt', () {
        expect(parseDate(formatDate(dt, thaiDigits: true)), dt);
        expect(parseDate(formatDateFull(dt, thaiDigits: true)), dt);
      });
    }
  });

  group('parseDate rejects bad input', () {
    test('no month / no numbers', () {
      expect(() => parseDate('ไม่ใช่วันที่'), throwsA(isA<ThaiNumException>()));
      expect(() => parseDate('มิถุนายน 2567'),
          throwsA(isA<ThaiNumException>())); // missing day
    });
  });
}
