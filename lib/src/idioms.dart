import 'exception.dart';
import 'numerals.dart';
import 'parse.dart';

/// A small, fixed set of Thai *counting idioms* — the only quantity words this
/// package recognises. These are deliberately **not** general ลักษณนาม
/// (classifiers): the set is closed to ครึ่ง / คู่ / โหล / กุรุส.
enum QuantityUnit {
  /// `'ครึ่ง'` — one half (value `0.5`).
  half,

  /// `'คู่'` — a pair (value `2`).
  pair,

  /// `'โหล'` — a dozen (value `12`).
  dozen,

  /// `'กุรุส'` — a gross, i.e. twelve dozen (value `144`).
  gross,
}

/// The Thai word for [unit]: `quantityWord(QuantityUnit.dozen)` → `'โหล'`.
String quantityWord(QuantityUnit unit) => switch (unit) {
      QuantityUnit.half => 'ครึ่ง',
      QuantityUnit.pair => 'คู่',
      QuantityUnit.dozen => 'โหล',
      QuantityUnit.gross => 'กุรุส',
    };

/// The numeric value of [unit]: `quantityValue(QuantityUnit.gross)` → `144`.
/// Returns a [num] because [QuantityUnit.half] is `0.5`.
num quantityValue(QuantityUnit unit) => switch (unit) {
      QuantityUnit.half => 0.5,
      QuantityUnit.pair => 2,
      QuantityUnit.dozen => 12,
      QuantityUnit.gross => 144,
    };

/// Parses a **narrow, opt-in** set of Thai counting idioms into a numeric
/// value. This is a focused convenience that sits *beside* the integer grammar
/// — it does not extend [parseInt] and does not recognise general classifiers.
///
/// Exactly the following inputs are supported:
///
///     parseQuantity('ครึ่ง');     // 0.5
///     parseQuantity('คู่');       // 2
///     parseQuantity('โหล');       // 12
///     parseQuantity('กุรุส');     // 144
///     parseQuantity('สองครึ่ง');  // 2.5   (an integer reading + trailing ครึ่ง = +0.5)
///     parseQuantity('สิบครึ่ง');  // 10.5
///     parseQuantity('สอง');       // 2     (a plain Thai integer reading)
///     parseQuantity('๑๒');        // 12    (digits accepted, like parseInt)
///
/// Rules and limits:
/// - A bare `'ครึ่ง'` / `'คู่'` / `'โหล'` / `'กุรุส'` reads as its unit value.
/// - A Thai integer reading optionally followed by a single trailing `'ครึ่ง'`
///   adds `0.5`. `'ครึ่ง'` may only appear once and only as the suffix.
/// - คู่ / โหล / กุรุส are **standalone only**: they may not be combined with a
///   number or with ครึ่ง here (e.g. `'สองโหล'` for 24 is intentionally *not*
///   supported — it needs a classifier grammar this package does not provide).
/// - The integer part is parsed by [parseInt], so it accepts the usual
///   `allowColloquial` / `lenient` / `strict` options.
///
/// Returns an `int` when the value is whole (`'โหล'` → `12`) and a `double`
/// when a half is present (`'สองครึ่ง'` → `2.5`). Throws [ThaiNumException]
/// on anything outside the supported set.
num parseQuantity(String words,
    {bool allowColloquial = false, bool lenient = false, bool strict = false}) {
  final s = toArabicDigits(words).trim();
  if (s.isEmpty) {
    throw const ThaiNumException(
        'thainum: empty input', null, null, ThaiNumError.emptyInput);
  }

  // Standalone single-unit words.
  if (s == 'คู่') return 2;
  if (s == 'โหล') return 12;
  if (s == 'กุรุส') return 144;
  if (s == 'ครึ่ง') return 0.5;

  // <integer> + trailing 'ครึ่ง' (e.g. 'สองครึ่ง' -> 2.5).
  if (s.endsWith('ครึ่ง')) {
    final head = s.substring(0, s.length - 'ครึ่ง'.length);
    if (head.isEmpty) {
      // Should have matched the bare 'ครึ่ง' above; defensive.
      return 0.5;
    }
    if (head.contains('ครึ่ง')) {
      throw ThaiNumException('thainum: "ครึ่ง" may appear only once', words,
          null, ThaiNumError.unknownToken);
    }
    final base = parseInt(head,
        allowColloquial: allowColloquial, lenient: lenient, strict: strict);
    return base + 0.5;
  }

  // Otherwise it must be a plain Thai integer reading.
  return parseInt(s,
      allowColloquial: allowColloquial, lenient: lenient, strict: strict);
}

/// Parses the idiom `'ครึ่งบาท'` ("half a baht") into **50 satang**, matching
/// the integer-satang convention used by [parseBaht].
///
///     parseHalfBaht('ครึ่งบาท'); // 50
///
/// This is intentionally a tiny, single-purpose helper. Anything other than
/// exactly `'ครึ่งบาท'` (after digit-normalisation and trimming) throws a
/// [ThaiNumException]; use [parseBaht] for general baht text.
int parseHalfBaht(String text) {
  final s = toArabicDigits(text).trim();
  if (s == 'ครึ่งบาท') return 50;
  throw ThaiNumException(
    'thainum: parseHalfBaht expects exactly "ครึ่งบาท"',
    text,
    null,
    ThaiNumError.invalidNumber,
  );
}
