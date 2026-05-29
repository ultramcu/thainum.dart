// Tests for the Thai lottery reading helpers (B9). Reading/date-only — no
// prize checking, no data.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('speakLotteryNumber', () {
    test('reads a six-digit prize number digit-by-digit', () {
      expect(speakLotteryNumber('123456'), 'หนึ่ง สอง สาม สี่ ห้า หก');
    });

    test('reads leading zeros', () {
      expect(speakLotteryNumber('012345'), 'ศูนย์ หนึ่ง สอง สาม สี่ ห้า');
    });

    test('accepts Thai numerals', () {
      expect(speakLotteryNumber('๐๑๒๓๔๕'), 'ศูนย์ หนึ่ง สอง สาม สี่ ห้า');
    });

    test('colloquialTwo reads 2 as โท', () {
      expect(speakLotteryNumber('222222', colloquialTwo: true),
          'โท โท โท โท โท โท');
    });

    test('honours a custom separator', () {
      expect(speakLotteryNumber('123456', separator: '-'),
          'หนึ่ง-สอง-สาม-สี่-ห้า-หก');
    });

    test('throws on the wrong length', () {
      expect(() => speakLotteryNumber('12345'), throwsFormatException);
      expect(() => speakLotteryNumber('1234567'), throwsFormatException);
    });

    test('throws on a non-digit character', () {
      expect(() => speakLotteryNumber('12-456'), throwsFormatException);
      expect(() => speakLotteryNumber('abcdef'), throwsFormatException);
    });
  });

  group('speakTwoDigit / speakThreeDigit', () {
    test('two digits', () {
      expect(speakTwoDigit('07'), 'ศูนย์ เจ็ด');
      expect(speakTwoDigit('๒๕'), 'สอง ห้า');
    });

    test('three digits', () {
      expect(speakThreeDigit('507'), 'ห้า ศูนย์ เจ็ด');
    });

    test('colloquialTwo on two/three digit', () {
      expect(speakTwoDigit('20', colloquialTwo: true), 'โท ศูนย์');
      expect(speakThreeDigit('234', colloquialTwo: true), 'โท สาม สี่');
    });

    test('length validation', () {
      expect(() => speakTwoDigit('5'), throwsFormatException);
      expect(() => speakTwoDigit('123'), throwsFormatException);
      expect(() => speakThreeDigit('12'), throwsFormatException);
      expect(() => speakThreeDigit('1234'), throwsFormatException);
    });
  });

  group('draw dates', () {
    test('isLotteryDrawDate is true on the 1st and 16th', () {
      expect(isLotteryDrawDate(DateTime(2024, 6, 1)), isTrue);
      expect(isLotteryDrawDate(DateTime(2024, 6, 16)), isTrue);
    });

    test('isLotteryDrawDate is false otherwise', () {
      expect(isLotteryDrawDate(DateTime(2024, 6, 2)), isFalse);
      expect(isLotteryDrawDate(DateTime(2024, 6, 15)), isFalse);
      expect(isLotteryDrawDate(DateTime(2024, 6, 30)), isFalse);
    });

    test('lotteryDrawDates returns the 1st and 16th', () {
      expect(lotteryDrawDates(2024, 6),
          [DateTime(2024, 6, 1), DateTime(2024, 6, 16)]);
    });

    test('lotteryDrawDates rejects an out-of-range month', () {
      expect(() => lotteryDrawDates(2024, 0), throwsFormatException);
      expect(() => lotteryDrawDates(2024, 13), throwsFormatException);
    });
  });
}
