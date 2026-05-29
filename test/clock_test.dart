// Colloquial-clock boundary coverage (A7). Every expected reading was produced
// by running the formatter and verified against standard Thai clock reading
// (ตี / โมงเช้า / เที่ยง / บ่าย / โมงเย็น / ทุ่ม / เที่ยงคืน).

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

DateTime _at(int h, [int m = 0]) => DateTime.utc(2024, 1, 1, h, m);

void main() {
  group('formatTime — formal 24-hour (นาฬิกา)', () {
    const cases = <int, String>{
      0: 'ศูนย์นาฬิกา',
      1: 'หนึ่งนาฬิกา',
      6: 'หกนาฬิกา',
      12: 'สิบสองนาฬิกา',
      13: 'สิบสามนาฬิกา',
      23: 'ยี่สิบสามนาฬิกา',
    };
    cases.forEach((h, want) {
      test('$h:00 == $want', () => expect(formatTime(_at(h)), want));
    });

    test('with minutes', () {
      expect(formatTime(_at(9, 5)), 'เก้านาฬิกาห้านาที');
      expect(formatTime(_at(14, 30)), 'สิบสี่นาฬิกาสามสิบนาที');
    });
  });

  group('formatClock — colloquial 6-hour boundaries', () {
    const cases = <int, String>{
      0: 'เที่ยงคืน',
      1: 'ตีหนึ่ง',
      6: 'หกโมงเช้า',
      11: 'สิบเอ็ดโมงเช้า',
      12: 'เที่ยง',
      13: 'บ่ายโมง',
      15: 'บ่ายสามโมง',
      18: 'หกโมงเย็น',
      19: 'หนึ่งทุ่ม',
      23: 'ห้าทุ่ม',
    };
    cases.forEach((h, want) {
      test('$h:00 == $want', () => expect(formatClock(_at(h)), want));
    });

    test('half hour reads ครึ่ง', () {
      expect(formatClock(_at(14, 30)), 'บ่ายสองโมงครึ่ง');
      expect(formatClock(_at(6, 30)), 'หกโมงเช้าครึ่ง');
    });

    test('odd minutes read …นาที', () {
      expect(formatClock(_at(9, 17)), 'เก้าโมงเช้าสิบเจ็ดนาที');
    });
  });
}
