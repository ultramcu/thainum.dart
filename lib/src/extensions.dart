// Dart-idiomatic receiver-style API over the top-level functions exposed by
// the other src files. Naming follows Effective Dart conventions:
//
//   - Methods (`toXxx()`, parens) for conversions that produce a new
//     representation. Matches `int.toRadixString()`, `DateTime.toIso8601String()`,
//     `Object.toString()`.
//   - Getters for `O(1)` properties / inherent components. Matches
//     `DateTime.year`, `int.isEven`, `String.length`.
//
// Currency-text shows up across receiver types as a polymorphic `toBahtText()`
// family. Money-unit safety (baht vs satang) is enforced through the [Baht] /
// [Satang] wrapper types, not by which `int` extension you happen to call.

import 'baht.dart';
import 'clock.dart';
import 'date.dart';
import 'extras.dart' as extras;
import 'format.dart';
// Aliased so the top-level `toThaiDigits` / `toArabicDigits` functions don't
// shadow the same-named extension methods we declare below on `int` / `String`.
import 'numerals.dart' as numerals;
import 'parse.dart' as parse;
import 'spell.dart';

/// Thai-number convenience methods on plain `int`.
///
/// Money methods on `int` interpret the receiver as a **whole-baht** amount,
/// because that is the unambiguous default. If your integer is a satang
/// amount, wrap it as `Satang(value)` and call `.toBahtText()` /
/// `.toDecimal()` / `.toThb()` — the wrapper makes the unit explicit at the
/// call site.
extension ThaiIntX on int {
  // ---- Numerals & formatting ------------------------------------------------

  /// Thai numeral form: `21.toThaiDigits()` → `'๒๑'`.
  String toThaiDigits() => numerals.toThaiDigits(toString());

  /// Thousands-separated decimal: `1234567.toThousandsString()` →
  /// `'1,234,567'`.
  String toThousandsString() => formatInt(this);

  // ---- Spelling -------------------------------------------------------------

  /// Spelled in Thai words: `21.toThaiWords()` → `'ยี่สิบเอ็ด'`.
  String toThaiWords() => spell(this);

  // ---- Currency -------------------------------------------------------------

  /// Baht text for a whole-baht amount: `100.toBahtText()` →
  /// `'หนึ่งร้อยบาทถ้วน'`.
  ///
  /// If your integer is a satang amount, call `Satang(value).toBahtText()`
  /// instead — the wrapper makes the unit explicit and the compiler can
  /// catch mixed-unit bugs.
  String toBahtText() => baht(this);

  // ---- Ordinals, fractions & Buddhist-Era years ----------------------------

  /// Ordinal form: `21.toThaiOrdinal()` → `'ที่ยี่สิบเอ็ด'`.
  String toThaiOrdinal() => extras.ordinal(this);

  /// Fraction with this integer as the numerator: `3.fraction(4)` →
  /// `'เศษสามส่วนสี่'`.
  String fraction(int denominator) => extras.fraction(this, denominator);

  /// Spelled Buddhist-Era year (input is the BE year, not CE):
  /// `2566.toBeYearText()` → `'พุทธศักราชสองพันห้าร้อยหกสิบหก'`.
  String toBeYearText() => extras.year(this);

  /// Convert a Common-Era year to Buddhist Era: `2026.toBuddhistYear()` →
  /// `2569`.
  int toBuddhistYear() => extras.ceToBe(this);

  /// Convert a Buddhist-Era year to Common Era: `2569.toCommonYear()` →
  /// `2026`.
  int toCommonYear() => extras.beToCe(this);
}

/// Thai-number convenience methods on `BigInt`. Use these once the value
/// exceeds the `int` range (~9.2 × 10¹⁸ on 64-bit, ~2.1 × 10⁹ on the web).
extension ThaiBigIntX on BigInt {
  /// Spelled in Thai words. Handles stacked `ล้าน` correctly (i.e.
  /// `10¹²` → `'หนึ่งล้านล้าน'`, `10¹⁸` → `'หนึ่งล้านล้านล้าน'`).
  String toThaiWords() => spellBigInt(this);

  /// Baht text for a whole-baht amount (the receiver is the baht count). If
  /// you actually have satang, wrap as `SatangBigInt(value).toBahtText()`.
  String toBahtText() => bahtBigInt(this);
}

/// Thai-number convenience methods on `double`.
///
/// **Lossy.** `double` cannot represent two decimal places exactly (`0.1 +
/// 0.2 != 0.3`). These extensions document the loss but still call the
/// internal `*FromDouble` routines for the common "I have a `double`,
/// just give me something printable" case. Prefer the integer-satang or
/// `String`-amount paths when accuracy matters.
extension ThaiDoubleX on double {
  /// Baht text from a float baht amount (lossy — uses 2-dp away-from-zero
  /// rounding internally).
  String toBahtText() => bahtFromDouble(this);

  /// Round a float baht amount to integer satang (lossy — see [toBahtText]).
  int toSatang() => satangFromFloat(this);
}

/// Thai-number convenience methods on `String`. Adds the reverse-parse and
/// numeral-conversion functions as methods on the string itself.
extension ThaiStringX on String {
  // ---- Numeral conversion --------------------------------------------------

  /// Replace ASCII digits with Thai numeral digits in this string:
  /// `'101'.toThaiDigits()` → `'๑๐๑'`.
  String toThaiDigits() => numerals.toThaiDigits(this);

  /// Replace Thai numeral digits with ASCII digits in this string:
  /// `'๑๐๑'.toArabicDigits()` → `'101'`.
  String toArabicDigits() => numerals.toArabicDigits(this);

  // ---- Reverse parsing -----------------------------------------------------

  /// Parse Thai number words back into an `int`. Throws `ThaiNumException`
  /// (a `FormatException`) on bad input.
  int parseThaiInt() => parse.parseInt(this);

  /// Parse Thai number words back into a `BigInt`.
  BigInt parseThaiBigInt() => parse.parseBigInt(this);

  /// Parse a Thai baht text into an integer satang amount.
  int parseThaiBaht() => parse.parseBaht(this);

  /// Parse a Thai date string (any of `formatDate` / `formatDateAbbr` /
  /// `formatDateFull` shapes) back into a `DateTime`.
  DateTime parseThaiDate() => parseDate(this);

  // ---- From-amount-string spellers -----------------------------------------

  /// Render this decimal amount string (e.g. `'21.21'.toBahtText()`) as Thai
  /// baht text. Exact: parses digits without going through `double`.
  String toBahtText() => bahtFromString(this);

  /// Spell a decimal value given as a string (e.g. `'12.34'.toThaiWords()`)
  /// in Thai words. Avoids the precision loss of [double].
  String toThaiWords() => spellDecimal(this);
}

/// Thai-number convenience methods on `DateTime`. Conversions to a Thai
/// string follow the `toIso8601String()` paradigm — they are methods.
/// Component accessors (`buddhistYear`, `thaiMonthName`, etc.) are getters
/// that parallel `DateTime.year` / `DateTime.month`.
extension ThaiDateTimeX on DateTime {
  /// Short Thai date: `'5 มิถุนายน 2567'`.
  String toThaiDate() => formatDate(this);

  /// Abbreviated Thai date: `'5 มิ.ย. 2567'`.
  String toThaiDateAbbr() => formatDateAbbr(this);

  /// Full Thai date with weekday and พ.ศ.: `'วันพุธที่ 5 มิถุนายน พ.ศ. 2567'`.
  String toThaiDateFull() => formatDateFull(this);

  /// Formal Thai clock time (นาฬิกา): `'สิบสี่นาฬิกาสามสิบนาที'`.
  String toThaiTime() => formatTime(this);

  /// Colloquial Thai clock (ตี / โมง / ทุ่ม): `'บ่ายสองโมงครึ่ง'`.
  String toThaiClock() => formatClock(this);

  /// Buddhist-Era year of this date: `2024` → `2567`. Parallels
  /// [DateTime.year].
  // Inlined `year + 543` to avoid name-shadowing the top-level `buddhistYear`
  // function exported from date.dart.
  int get buddhistYear => year + 543;

  /// Full Thai month name: `month == 6` → `'มิถุนายน'`. Parallels
  /// [DateTime.month] (which is the month index).
  String get thaiMonthName => monthTh(month);

  /// Abbreviated Thai month name: `month == 6` → `'มิ.ย.'`.
  String get thaiMonthAbbr => monthAbbrTh(month);

  /// Full `'วัน...'` weekday name: Wed → `'วันพุธ'`. Parallels
  /// [DateTime.weekday] (which is the weekday index).
  String get thaiWeekdayName => weekdayTh(this);

  /// Abbreviated weekday: Wed → `'พ.'`.
  String get thaiWeekdayAbbr => weekdayAbbrTh(this);
}

/// Thai-number convenience methods on `Duration`.
extension ThaiDurationX on Duration {
  /// Duration spelled in Thai: `Duration(minutes: 90).toThaiText()` →
  /// `'หนึ่งชั่วโมงสามสิบนาที'`.
  String toThaiText() => formatDuration(this);
}
