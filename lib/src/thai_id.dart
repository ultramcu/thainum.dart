import 'exception.dart';
import 'numerals.dart';
import 'speak.dart';

/// The category a Thai National ID encodes in its leading digit, per the
/// Department of Provincial Administration (DOPA, กรมการปกครอง).
enum ThaiIdKind {
  /// Leading 1: Thai national whose birth was registered within the deadline,
  /// born on/after 1 Jan 1984 (พ.ศ. 2527).
  thaiBornRegisteredOnTime,

  /// Leading 2: Thai national whose birth was registered late, born on/after
  /// 1 Jan 1984.
  thaiBornRegisteredLate,

  /// Leading 3: Thai national who was already in the household registry before
  /// 1 Jan 1984.
  thaiInRegistryBefore1984,

  /// Leading 4: Thai national born before 1 Jan 1984 but not yet in the
  /// registry at the 1984 census.
  thaiBornBefore1984NotRegistered,

  /// Leading 5: Thai national added to the registry later (missed the census,
  /// or special cases).
  thaiAddedLater,

  /// Leading 6: foreign national living in Thailand temporarily, or who
  /// entered unlawfully.
  foreignerTemporary,

  /// Leading 7: child of a category-6 person, born in Thailand.
  childOfForeignerTemporary,

  /// Leading 8: naturalised Thai citizen or a foreigner with permanent
  /// residence.
  naturalisedOrPermanentResident,

  /// Leading digit 0 or 9 (not assigned by DOPA to a person category), or an
  /// otherwise unrecognised id. Returned conservatively rather than guessing.
  unknown,
}

const int _asciiZero = 0x30;
const int _asciiNine = 0x39;

/// Strips dashes/spaces and converts Thai numerals to ASCII, returning the
/// bare 13 ASCII digits of a Thai National / personal Tax ID.
///
///     parseThaiId('1-2345-67890-12-1'); // '1234567890121'
///     parseThaiId('๑๑๐๑๗๐๐๒๓๐๗๐๕');   // '1101700230705'
///
/// Throws [ThaiNumException] if the result is not exactly 13 ASCII digits.
String parseThaiId(String id) {
  final arabic = toArabicDigits(id);
  final buf = StringBuffer();
  for (final r in arabic.runes) {
    if (r >= _asciiZero && r <= _asciiNine) {
      buf.writeCharCode(r);
    } else if (r == 0x2D || r == 0x20) {
      // dash or space — allowed separators
      continue;
    } else {
      throw ThaiNumException('thainum: invalid character in Thai ID', id, null,
          ThaiNumError.invalidThaiIdChar);
    }
  }
  final digits = buf.toString();
  if (digits.length != 13) {
    throw ThaiNumException(
      'thainum: Thai ID must be exactly 13 digits (got ${digits.length})',
      id,
      null,
      ThaiNumError.thaiIdWrongLength,
    );
  }
  return digits;
}

/// Computes the MOD-11 check digit for the first 12 digits of [digits13].
///
/// For digits d0..d12, `sum = Σ d[i]*(13-i)` for i=0..11 (weights 13,12,…,2);
/// the check digit is `(11 - (sum % 11)) % 10`.
///
/// Note: the third digit (index 2) carries weight 11, and `d*11 mod 11 == 0`
/// for every digit, so a change to that single digit is invisible to the
/// checksum — an inherent blind spot of the MOD-11 weighting, not a defect.
int _checkDigit(String digits13) {
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = digits13.codeUnitAt(i) - _asciiZero;
    sum += d * (13 - i);
  }
  return (11 - (sum % 11)) % 10;
}

/// Returns true iff [id] is a syntactically valid Thai National ID: exactly
/// 13 digits (after stripping dashes/spaces and converting Thai numerals) with
/// a correct MOD-11 checksum.
///
///     isValidThaiId('1101700230705'); // depends on the checksum
bool isValidThaiId(String id) {
  String digits;
  try {
    digits = parseThaiId(id);
  } on ThaiNumException {
    return false;
  }
  final d12 = digits.codeUnitAt(12) - _asciiZero;
  return d12 == _checkDigit(digits);
}

/// Returns true iff [id] is a valid Thai personal Tax ID. For individuals the
/// Tax ID equals the National ID, so this delegates to [isValidThaiId].
bool isValidThaiTaxId(String id) => isValidThaiId(id);

/// Formats a Thai National ID into the canonical `X-XXXX-XXXXX-XX-X` shape.
///
///     formatThaiId('1234567890121'); // '1-2345-67890-12-1'
///
/// Accepts already-grouped or Thai-numeral input (it re-parses via
/// [parseThaiId]). Throws [ThaiNumException] if not 13 digits.
String formatThaiId(String id) {
  final d = parseThaiId(id);
  return '${d.substring(0, 1)}-${d.substring(1, 5)}-${d.substring(5, 10)}-'
      '${d.substring(10, 12)}-${d.substring(12, 13)}';
}

/// Classifies [id] by its leading digit per DOPA. Returns [ThaiIdKind.unknown]
/// for leading digit 0/9 or any input that is not 13 digits, rather than
/// guessing.
ThaiIdKind classifyThaiId(String id) {
  String digits;
  try {
    digits = parseThaiId(id);
  } on ThaiNumException {
    return ThaiIdKind.unknown;
  }
  switch (digits.codeUnitAt(0) - _asciiZero) {
    case 1:
      return ThaiIdKind.thaiBornRegisteredOnTime;
    case 2:
      return ThaiIdKind.thaiBornRegisteredLate;
    case 3:
      return ThaiIdKind.thaiInRegistryBefore1984;
    case 4:
      return ThaiIdKind.thaiBornBefore1984NotRegistered;
    case 5:
      return ThaiIdKind.thaiAddedLater;
    case 6:
      return ThaiIdKind.foreignerTemporary;
    case 7:
      return ThaiIdKind.childOfForeignerTemporary;
    case 8:
      return ThaiIdKind.naturalisedOrPermanentResident;
    default:
      return ThaiIdKind.unknown;
  }
}

/// Reads a Thai National ID digit-by-digit as Thai words (อ่านเรียงตัว) via
/// [speakDigits].
///
///     speakThaiId('1101700230705');
///     // 'หนึ่ง หนึ่ง ศูนย์ หนึ่ง เจ็ด ศูนย์ ศูนย์ สอง สาม ศูนย์ เจ็ด ศูนย์ ห้า'
///
/// Throws [ThaiNumException] if [id] is not 13 digits.
String speakThaiId(String id) => speakDigits(parseThaiId(id));
