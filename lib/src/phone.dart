import 'exception.dart';
import 'numerals.dart';
import 'speak.dart';

const int _asciiZero = 0x30;
const int _asciiNine = 0x39;

/// Keeps only the digit characters of [s], converting Thai numerals to ASCII
/// first and dropping every separator (spaces, dashes, dots, parentheses, a
/// leading `+`, …). The result is a bare ASCII digit string.
String _digitsOnly(String s) {
  final arabic = toArabicDigits(s);
  final buf = StringBuffer();
  for (final r in arabic.runes) {
    if (r >= _asciiZero && r <= _asciiNine) {
      buf.writeCharCode(r);
    }
  }
  return buf.toString();
}

/// Strips a leading Thailand country code (`66`, optionally introduced by a
/// `+`) from a digit string and restores the national leading `0`, so both
/// `'+66812345678'` and `'0812345678'` reduce to the same national-format
/// `'0812345678'`. A string that does not start with `66` is returned
/// unchanged.
String _toNational(String raw, String digits) {
  // Only treat a leading 66 as a country code when the original input carried a
  // '+' or the 66-form length matches a national number with the 0 restored.
  final hadPlus = raw.trimLeft().startsWith('+');
  if (digits.startsWith('66') && (hadPlus || digits.length == 11)) {
    return '0${digits.substring(2)}';
  }
  return digits;
}

/// The category a Thai phone number falls into, inferred from its prefix and
/// length. Returned conservatively: anything that does not clearly match a
/// known pattern is [unknown] rather than guessed.
enum ThaiPhoneKind {
  /// A 10-digit mobile number: `0` + `6`/`8`/`9` + 8 more digits
  /// (e.g. `081-234-5678`).
  mobile,

  /// A fixed-line (landline) number: `0` + an area code + 8 more digits, 9
  /// digits total (e.g. Bangkok `02-123-4567`, provincial `0X-XXX-XXXX`).
  landline,

  /// A toll-free / special commercial number beginning `1800`.
  tollFree,

  /// A short service code (3–4 digits, often `1xxx`, e.g. `1669`, `191`).
  shortCode,

  /// Does not match any recognised Thai pattern.
  unknown,
}

/// Classifies a Thai phone number by prefix and length.
///
///     thaiPhoneKind('0812345678'); // ThaiPhoneKind.mobile
///     thaiPhoneKind('021234567');  // ThaiPhoneKind.landline (Bangkok)
///     thaiPhoneKind('1800000000'); // ThaiPhoneKind.tollFree
///     thaiPhoneKind('1669');       // ThaiPhoneKind.shortCode
///     thaiPhoneKind('12345');      // ThaiPhoneKind.unknown
///
/// Separators, spaces, Thai numerals and a `+66` country code are accepted (the
/// `+66` form is normalised to the national `0…` form first). The rules are:
///
/// * **mobile** — 10 digits, `0` followed by `6`, `8` or `9`.
/// * **tollFree** — begins with `1800` (8–10 digits).
/// * **landline** — 9 digits beginning with `0` that is not a mobile prefix
///   (Bangkok `02…`, provincial `03…`/`04…`/`05…`/`07…`, etc.).
/// * **shortCode** — 3 or 4 digits not otherwise matched (e.g. `191`, `1669`).
/// * **unknown** — everything else.
///
/// Distinguishing landline *area codes* from one another is best-effort: this
/// only reports the broad `landline` kind, not the province, because Thai area
/// codes are variable-length and overlap the mobile space at the prefix level.
ThaiPhoneKind thaiPhoneKind(String s) {
  final digits = _toNational(s, _digitsOnly(s));
  if (digits.isEmpty) return ThaiPhoneKind.unknown;

  // Toll-free 1800… (checked before short codes so 1800xxxxxx isn't a code).
  if (digits.startsWith('1800') && digits.length >= 8 && digits.length <= 10) {
    return ThaiPhoneKind.tollFree;
  }

  if (digits.startsWith('0') && digits.length == 10) {
    final second = digits[1];
    if (second == '6' || second == '8' || second == '9') {
      return ThaiPhoneKind.mobile;
    }
    return ThaiPhoneKind.unknown;
  }

  if (digits.startsWith('0') && digits.length == 9) {
    return ThaiPhoneKind.landline;
  }

  // Short service codes: 3–4 digits, not starting with 0.
  if ((digits.length == 3 || digits.length == 4) && !digits.startsWith('0')) {
    return ThaiPhoneKind.shortCode;
  }

  return ThaiPhoneKind.unknown;
}

/// Formats a Thai phone number with conventional grouping.
///
///     formatThaiPhone('0812345678'); // '081-234-5678'
///     formatThaiPhone('๐๘๑๒๓๔๕๖๗๘'); // '081-234-5678'
///     formatThaiPhone('021234567');  // '02-123-4567'
///
/// Existing separators, spaces, Thai numerals and a leading `+66` country code
/// are accepted (the `+66` form is normalised to `0…` first). The number is
/// first classified with [thaiPhoneKind] and grouped only when the *kind*
/// warrants it, so a number that merely happens to be 10 digits long (e.g. a
/// `1800…` toll-free) is never mis-grouped as a mobile number:
///
/// * **mobile** (10-digit `0` + `6`/`8`/`9`) → `3-3-4` (`081-234-5678`).
/// * **landline** (9-digit) → `2-3-4` (`02-123-4567`). This is the common
///   Bangkok shape and a reasonable default for provincial numbers; precise
///   provincial area-code lengths vary, so landline grouping is **best-effort**.
/// * **tollFree** (`1800…`), **shortCode** (`191`, `1669`, …) and anything of
///   an **unknown** kind are returned as their bare digit string (no separators
///   inserted) rather than mis-grouped.
///
/// If the input contains no digits at all it is returned **unchanged** (a
/// formatter does not silently emit an empty string).
String formatThaiPhone(String s) {
  final digits = _toNational(s, _digitsOnly(s));
  if (digits.isEmpty) return s;
  switch (thaiPhoneKind(s)) {
    case ThaiPhoneKind.mobile:
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-'
          '${digits.substring(6)}';
    case ThaiPhoneKind.landline:
      return '${digits.substring(0, 2)}-${digits.substring(2, 5)}-'
          '${digits.substring(5)}';
    case ThaiPhoneKind.tollFree:
    case ThaiPhoneKind.shortCode:
    case ThaiPhoneKind.unknown:
      return digits;
  }
}

/// Normalises a Thai national number to E.164 international form (`+66…`).
///
///     normalizeThaiPhone('0812345678'); // '+66812345678'
///     normalizeThaiPhone('02-123-4567'); // '+66212345678'
///     normalizeThaiPhone('+66812345678'); // '+66812345678' (idempotent)
///
/// Assumptions: the input is a Thailand number, so a single leading national
/// trunk `0` is dropped and `+66` is prefixed. A number already in `+66` /
/// `66…` form is returned in canonical `+66…` form. Separators, spaces and Thai
/// numerals are accepted. Throws [ThaiNumException] if no digits remain.
String normalizeThaiPhone(String s) {
  final national = _toNational(s, _digitsOnly(s));
  if (national.isEmpty) {
    throw ThaiNumException(
      'thainum: no digits in phone number',
      s,
      null,
      ThaiNumError.invalidNumber,
    );
  }
  // Drop a single national trunk 0, then prefix +66.
  final body = national.startsWith('0') ? national.substring(1) : national;
  return '+66$body';
}

/// Reads a Thai phone number digit-by-digit in Thai words (อ่านเรียงตัว) via
/// [speakDigits].
///
///     speakThaiPhone('0812345678');
///     // 'ศูนย์ แปด หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด'
///     speakThaiPhone('0812345678', colloquialTwo: true);
///     // '... โท ...'  (2 read as โท, the phone-distinct form)
///
/// Separators, spaces, Thai numerals and a leading `+66` are accepted; the
/// number is normalised to its national `0…` form first, so `'+66812345678'`
/// reads the same as `'0812345678'`. With [colloquialTwo] the digit `2` reads
/// as `'โท'`.
String speakThaiPhone(String s, {bool colloquialTwo = false}) {
  final national = _toNational(s, _digitsOnly(s));
  return speakDigits(national, colloquialTwo: colloquialTwo);
}
