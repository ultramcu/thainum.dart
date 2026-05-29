import 'exception.dart';
import 'numerals.dart';
import 'speak.dart';

const int _asciiZero = 0x30;
const int _asciiNine = 0x39;

/// Counts the ASCII digits in [s] after normalising Thai numerals, and returns
/// the digit-only string, or throws [ThaiNumException] if any non-digit
/// character is present or the length is not [expected].
String _requireDigits(String s, int expected, String what) {
  final arabic = toArabicDigits(s);
  final buf = StringBuffer();
  for (final r in arabic.runes) {
    if (r >= _asciiZero && r <= _asciiNine) {
      buf.writeCharCode(r);
    } else {
      throw ThaiNumException(
        'thainum: $what must be exactly $expected digits',
        s,
        null,
        ThaiNumError.invalidNumber,
      );
    }
  }
  final digits = buf.toString();
  if (digits.length != expected) {
    throw ThaiNumException(
      'thainum: $what must be exactly $expected digits '
      '(got ${digits.length})',
      s,
      null,
      ThaiNumError.invalidNumber,
    );
  }
  return digits;
}

/// Reads a six-digit Thai lottery prize number ([sixDigits]) digit-by-digit in
/// Thai words (อ่านเรียงตัว) — the way a lottery number is read aloud, never as
/// a quantity.
///
///     speakLotteryNumber('123456'); // 'หนึ่ง สอง สาม สี่ ห้า หก'
///     speakLotteryNumber('๐๑๒๓๔๕'); // 'ศูนย์ หนึ่ง สอง สาม สี่ ห้า'
///
/// Both Arabic (`0-9`) and Thai (`๐-๙`) digits are accepted. With
/// [colloquialTwo] the digit `2` reads as `'โท'`; [separator] controls the join
/// (default a single space). Throws [ThaiNumException] if [sixDigits] is not
/// exactly six digits (any non-digit character is rejected).
String speakLotteryNumber(String sixDigits,
    {String separator = ' ', bool colloquialTwo = false}) {
  final d = _requireDigits(sixDigits, 6, 'a lottery number');
  return speakDigits(d, separator: separator, colloquialTwo: colloquialTwo);
}

/// Reads a two-digit running number (เลขท้าย 2 ตัว) digit-by-digit.
///
///     speakTwoDigit('07'); // 'ศูนย์ เจ็ด'
///
/// See [speakLotteryNumber] for the [separator] / [colloquialTwo] options and
/// the digit handling. Throws [ThaiNumException] if [twoDigits] is not exactly
/// two digits.
String speakTwoDigit(String twoDigits,
    {String separator = ' ', bool colloquialTwo = false}) {
  final d = _requireDigits(twoDigits, 2, 'a two-digit number');
  return speakDigits(d, separator: separator, colloquialTwo: colloquialTwo);
}

/// Reads a three-digit running number (เลขท้าย/เลขหน้า 3 ตัว) digit-by-digit.
///
///     speakThreeDigit('507'); // 'ห้า ศูนย์ เจ็ด'
///
/// See [speakLotteryNumber] for the [separator] / [colloquialTwo] options.
/// Throws [ThaiNumException] if [threeDigits] is not exactly three digits.
String speakThreeDigit(String threeDigits,
    {String separator = ' ', bool colloquialTwo = false}) {
  final d = _requireDigits(threeDigits, 3, 'a three-digit number');
  return speakDigits(d, separator: separator, colloquialTwo: colloquialTwo);
}

/// True iff [d] falls on a Thai Government Lottery draw date.
///
/// The Thai Government Lottery (สลากกินแบ่งรัฐบาล) is drawn twice a month, on
/// the 1st and the 16th. This checks the calendar day only — it does **not**
/// know about the rare official schedule shifts (e.g. when a draw is moved off
/// a public holiday), so treat it as a convenience predicate, not an authority.
///
///     isLotteryDrawDate(DateTime(2024, 6, 1));  // true
///     isLotteryDrawDate(DateTime(2024, 6, 16)); // true
///     isLotteryDrawDate(DateTime(2024, 6, 17)); // false
bool isLotteryDrawDate(DateTime d) => d.day == 1 || d.day == 16;

/// The two regular Thai Government Lottery draw dates in [month] of [year] —
/// the 1st and the 16th — as `DateTime`s at midnight (local time, like the
/// `DateTime(year, month, day)` constructor).
///
///     lotteryDrawDates(2024, 6); // [2024-06-01, 2024-06-16]
///
/// As with [isLotteryDrawDate] this is the regular schedule and does not encode
/// official holiday shifts. Throws [ThaiNumException] if [month] is not 1..12.
List<DateTime> lotteryDrawDates(int year, int month) {
  if (month < 1 || month > 12) {
    throw ThaiNumException(
      'thainum: month must be 1..12 (got $month)',
      '$month',
      null,
      ThaiNumError.invalidNumber,
    );
  }
  return [DateTime(year, month, 1), DateTime(year, month, 16)];
}
