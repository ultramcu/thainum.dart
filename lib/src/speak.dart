import 'numerals.dart';
import 'spell.dart' show numberThai;

const int _asciiZero = 0x30; // 0
const int _asciiNine = 0x39; // 9

/// Reads each digit in [s] individually as a Thai word (อ่านเรียงตัว) — a
/// digit-by-digit reading rather than a quantity. Phone numbers, account
/// numbers, PINs and years-read-as-digits use this form.
///
///     speakDigits('2566');        // 'สอง ห้า หก หก'
///     speakDigits('081-234-5678'); // 'ศูนย์ แปด หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด'
///
/// Both Arabic (`0-9`) and Thai (`๐-๙`) digits are accepted. Every non-digit
/// character acts as a delimiter: a run of one or more non-digits between two
/// emitted digit-words collapses to exactly one [separator] (default a single
/// space), and there is never a leading or trailing separator. Input with no
/// digits returns `''`.
///
/// With [colloquialTwo] set to true the digit `2` is read as `'โท'` — the
/// spoken-distinctness form used when reading digits aloud (e.g. over the
/// phone) so it is not confused with `'สาม'`. All other digits are unchanged.
///
///     speakDigits('2566', colloquialTwo: true); // 'โท ห้า หก หก'
String speakDigits(String s,
    {String separator = ' ', bool colloquialTwo = false}) {
  // Normalise Thai numerals to ASCII so we only deal with one range.
  final norm = toArabicDigits(s);
  final buf = StringBuffer();
  var emitted = false;
  for (final r in norm.runes) {
    if (r >= _asciiZero && r <= _asciiNine) {
      if (emitted) buf.write(separator);
      final d = r - _asciiZero;
      if (d == 2 && colloquialTwo) {
        buf.write('โท');
      } else {
        buf.write(numberThai[d]);
      }
      emitted = true;
    }
    // Non-digits are skipped here; the `emitted` flag inserts exactly one
    // separator before the next emitted digit, collapsing any run of
    // delimiters and avoiding leading/trailing separators.
  }
  return buf.toString();
}
