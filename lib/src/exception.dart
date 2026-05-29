/// A machine-readable classification of every distinct failure that the
/// thainum parser, speller, baht/decimal/date/ID readers can throw.
///
/// Each value corresponds to exactly one kind of malformed input. Use it to
/// branch on the failure programmatically instead of matching on the
/// (English) [ThaiNumException.message] string:
///
///     try {
///       parseInt('สิบสิบ');
///     } on ThaiNumException catch (e) {
///       if (e.code == ThaiNumError.misplacedPlaceWord) { /* ... */ }
///     }
///
/// The set is purely additive; [ThaiNumException.code] is `null` only for
/// exceptions constructed without one (so older code paths keep working).
enum ThaiNumError {
  /// The input was empty (after trimming / lenient normalization).
  emptyInput,

  /// A token run was not recognized as any number word, or a fractional part
  /// contained something other than a bare single-digit word.
  unknownToken,

  /// Two units digits appeared back-to-back with no place word between them
  /// (e.g. `'สองสาม'`).
  twoDigitsInARow,

  /// A place word (สิบ/ร้อย/พัน/หมื่น/แสน) was repeated or ascended within a
  /// group (e.g. `'สิบสิบ'`, `'ร้อยพัน'`).
  misplacedPlaceWord,

  /// A word appeared where it is not allowed — a stray sign (`'ลบ'`) or a
  /// `'ศูนย์'` inside a compound number.
  misplacedWord,

  /// `'เอ็ด'` (a trailing one) was followed by a place word (e.g. `'เอ็ดสิบ'`).
  etCannotPrecedePlace,

  /// `'ยี่'` was used anywhere other than directly before สิบ (e.g. `'ยี่ร้อย'`).
  yiMustPrecedeSib,

  /// The ล้าน-run lengths between groups did not strictly decrease
  /// (e.g. `'ล้านล้านห้าล้าน'`).
  millionGroupsOutOfOrder,

  /// A `'ลบ'` (minus) was not followed by a number.
  negAloneNotNumber,

  /// The satang amount in a baht text was outside 0..99.
  satangOutOfRange,

  /// A parsed value did not fit in a Dart `int` (use the `*BigInt` parser).
  overflowsInt,

  /// More than one `'จุด'` (decimal point) appeared.
  multipleDecimalPoints,

  /// A `'จุด'` had no fractional digits after it.
  missingFractionalPart,

  /// A `'จุด'` had no integer part before it.
  missingIntegerPart,

  /// A numeric string was not a valid (optionally-signed) decimal.
  invalidNumber,

  /// No Thai month name was found in a date string.
  noMonthFound,

  /// A date string was missing a day and/or a year.
  missingDayOrYear,

  /// A date string named an impossible calendar date.
  invalidDate,

  /// A Thai ID contained a character that is neither a digit nor a separator.
  invalidThaiIdChar,

  /// A Thai ID did not have exactly 13 digits.
  thaiIdWrongLength,

  /// Strict parse mode rejected a non-standard tens form: a tens place fed by
  /// a digit-1 (`'หนึ่งสิบ'`) or by a plain digit-2 not written as ยี่
  /// (`'สองสิบ'`). Lenient (default) parsing accepts these.
  nonStandardTensDigit,

  /// The `กว่า` qualifier ([moreThan]) was given a number that is not a
  /// positive round magnitude (10, 20, …, 100, 1000, …).
  notRoundMagnitude,
}

/// Thrown when Thai number/date words or numeric input cannot be parsed.
///
/// It implements [FormatException] so callers that catch [FormatException]
/// (the idiomatic Dart parse-failure type) also catch this.
///
/// In addition to the English [message] (kept stable for backward
/// compatibility), it carries a machine-readable [code] and a Thai-language
/// [messageTh]. Both are additive: [toString] and [message] are unchanged.
class ThaiNumException implements FormatException {
  /// Creates a [ThaiNumException] with a human-readable English [message], an
  /// optional [source] string and [offset], and an optional machine-readable
  /// [code].
  const ThaiNumException(this.message, [this.source, this.offset, this.code]);

  @override
  final String message;

  @override
  final dynamic source;

  @override
  final int? offset;

  /// A machine-readable classification of the failure, or `null` if the
  /// exception was created without one.
  final ThaiNumError? code;

  /// A Thai-language rendering of [message].
  ///
  /// When [code] is set this is a fixed Thai phrase for that failure class;
  /// otherwise it falls back to the English [message]. This getter is purely
  /// additive and never affects [toString].
  String get messageTh {
    final c = code;
    if (c == null) return message;
    return _messagesTh[c] ?? message;
  }

  /// Renders a two-line diagnostic with a caret under the offending token,
  /// when both [source] (a String) and [offset] are available:
  ///
  ///     สองสาม
  ///        ^
  ///
  /// Returns just the [message] when there is no usable source/offset.
  String describe() {
    final src = source;
    final off = offset;
    if (src is! String || off == null || off < 0 || off > src.length) {
      return message;
    }
    return '$message\n$src\n${' ' * off}^';
  }

  @override
  String toString() {
    final src = source;
    if (src is String) {
      return 'ThaiNumException: $message ("$src")';
    }
    return 'ThaiNumException: $message';
  }
}

/// Fixed Thai-language messages, one per [ThaiNumError].
const Map<ThaiNumError, String> _messagesTh = {
  ThaiNumError.emptyInput: 'thainum: ข้อมูลว่างเปล่า',
  ThaiNumError.unknownToken: 'thainum: พบคำที่ไม่รู้จัก',
  ThaiNumError.twoDigitsInARow: 'thainum: มีเลขโดดสองตัวติดกัน',
  ThaiNumError.misplacedPlaceWord: 'thainum: คำบอกหลักวางผิดตำแหน่ง',
  ThaiNumError.misplacedWord: 'thainum: คำวางผิดตำแหน่ง',
  ThaiNumError.etCannotPrecedePlace: 'thainum: "เอ็ด" ตามด้วยคำบอกหลักไม่ได้',
  ThaiNumError.yiMustPrecedeSib: 'thainum: "ยี่" ต้องตามด้วย "สิบ"',
  ThaiNumError.millionGroupsOutOfOrder: 'thainum: ลำดับกลุ่ม "ล้าน" ไม่ถูกต้อง',
  ThaiNumError.negAloneNotNumber: 'thainum: "ลบ" เพียงคำเดียวไม่ใช่จำนวน',
  ThaiNumError.satangOutOfRange: 'thainum: ค่าสตางค์อยู่นอกช่วง 0..99',
  ThaiNumError.overflowsInt: 'thainum: ค่าเกินขนาด int (ใช้ parseBigInt)',
  ThaiNumError.multipleDecimalPoints: 'thainum: มี "จุด" มากกว่าหนึ่งจุด',
  ThaiNumError.missingFractionalPart: 'thainum: ไม่มีเลขทศนิยมหลัง "จุด"',
  ThaiNumError.missingIntegerPart: 'thainum: ไม่มีเลขจำนวนเต็มหน้า "จุด"',
  ThaiNumError.invalidNumber: 'thainum: รูปแบบจำนวนไม่ถูกต้อง',
  ThaiNumError.noMonthFound: 'thainum: ไม่พบชื่อเดือนภาษาไทย',
  ThaiNumError.missingDayOrYear: 'thainum: ต้องมีทั้งวันและปี',
  ThaiNumError.invalidDate: 'thainum: วันที่ไม่ถูกต้อง',
  ThaiNumError.invalidThaiIdChar:
      'thainum: มีอักขระที่ไม่ถูกต้องในเลขบัตรประชาชน',
  ThaiNumError.thaiIdWrongLength: 'thainum: เลขบัตรประชาชนต้องมี 13 หลักพอดี',
  ThaiNumError.nonStandardTensDigit:
      'thainum: รูปหลักสิบไม่เป็นมาตรฐาน (ใช้ "ยี่สิบ" แทน "สองสิบ")',
  ThaiNumError.notRoundMagnitude:
      'thainum: "กว่า" ใช้ได้เฉพาะกับจำนวนเต็มหลัก (สิบ ร้อย พัน หมื่น แสน ล้าน)',
};
