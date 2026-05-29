// Abbreviated large-number reading (A5): render values >= 10^6 with a single
// "scale unit" word spaced a factor of 1000 apart — the สากล พัน/ล้าน
// convention. The coefficient is computed exactly from the decimal digit
// string (never via floating-point division), mirroring the integer/string
// approach used by `formatSatang`.
//
// Scale units (powers of ten, 1000 apart):
//   10^6  = ล้าน          10^15 = พันล้านล้าน
//   10^9  = พันล้าน        10^18 = ล้านล้านล้าน
//   10^12 = ล้านล้าน       ...
//
// General rule for the unit at 10^(6+3k), k >= 0: write 'ล้าน' repeated
// (k ~/ 2 + 1) times, prefixed with 'พัน' when k is odd.

import 'format.dart';
import 'numerals.dart';
import 'spell.dart';

const int _asciiZeroCode = 0x30;

/// Builds the Thai scale-unit word for the unit at `10^(6+3k)`.
///
/// `k == 0` → `'ล้าน'`, `1` → `'พันล้าน'`, `2` → `'ล้านล้าน'`,
/// `3` → `'พันล้านล้าน'`, `4` → `'ล้านล้านล้าน'`, … . Computed generatively so
/// it is correct at arbitrary `BigInt` scale.
String _unitWord(int k) {
  final repeats = k ~/ 2 + 1;
  final b = StringBuffer();
  if (k.isOdd) b.write('พัน');
  for (var i = 0; i < repeats; i++) {
    b.write('ล้าน');
  }
  return b.toString();
}

/// A coefficient resolved against a scale unit: its integer part (1..999), its
/// trimmed fractional digit string (may be empty), and the chosen unit index k.
class _Coeff {
  _Coeff(this.intPart, this.frac, this.k);

  /// Integer part of the coefficient, a string holding 1..999.
  final String intPart;

  /// Trimmed fractional digits (no trailing zeros); empty when whole.
  final String frac;

  /// Scale-unit index: the unit is `10^(6+3k)`.
  final int k;
}

/// Rounds the magnitude digit string [mag] (no sign, already known to be
/// `>= 10^6`) against the largest scale unit, half-away-from-zero to [decimals]
/// places, handling the carry into the next unit. Float-free: all arithmetic is
/// on the digit string.
_Coeff _resolve(String mag, int decimals) {
  // Largest k with 10^(6+3k) <= value, i.e. value has at least 6+3k+1 digits.
  final n = mag.length; // n >= 7 here
  var k = (n - 1 - 6) ~/ 3;
  var d = 6 + 3 * k; // number of fractional (low) digits for this unit

  // Split into integer part (high) and fractional part (low d digits).
  var intDigits = mag.substring(0, n - d);
  var fracDigits = mag.substring(n - d);

  // Round the fractional part to `decimals` places, half-away-from-zero.
  // Everything below stays as integer digit-string arithmetic.
  if (decimals < fracDigits.length) {
    final keep = fracDigits.substring(0, decimals);
    final roundUp = fracDigits.codeUnitAt(decimals) - _asciiZeroCode >= 5;
    var combined = intDigits + keep; // integer view of intPart.keep
    if (roundUp) {
      combined = _incDecimalString(combined);
    }
    // Re-split: the last `decimals` chars are the fractional part.
    if (decimals == 0) {
      intDigits = combined;
      fracDigits = '';
    } else {
      // `combined` length is at least `decimals` (intDigits was >= 1 char).
      intDigits = combined.substring(0, combined.length - decimals);
      fracDigits = combined.substring(combined.length - decimals);
    }
  }
  // else: decimals >= available fraction digits → no rounding needed.

  // Carry promotion: a round-up can push the integer part to >= 1000, which
  // means the value reached the next scale unit (coefficient becomes 1.000…).
  // Promote one unit at a time; after promotion the fraction is all zeros.
  while (intDigits.length > 3) {
    k += 1;
    d += 3;
    // Re-derive from the (now larger-unit) split: integer part is the digits
    // above the new unit, fraction is the rest. But we already rounded; on
    // promotion the coefficient is exactly 1 followed by zeros.
    intDigits = intDigits.substring(0, intDigits.length - 3);
    fracDigits = ''; // promoted coefficient is whole (1.000…)
  }

  // Trim trailing zeros from the fractional part.
  var end = fracDigits.length;
  while (end > 0 && fracDigits.codeUnitAt(end - 1) == _asciiZeroCode) {
    end--;
  }
  fracDigits = fracDigits.substring(0, end);

  return _Coeff(intDigits, fracDigits, k);
}

/// Adds 1 to the lowest place of a non-negative decimal digit string,
/// propagating the carry; grows the string by one digit on overflow.
String _incDecimalString(String s) {
  final units = s.codeUnits.toList();
  var i = units.length - 1;
  while (i >= 0) {
    if (units[i] == 0x39) {
      units[i] = _asciiZeroCode;
      i--;
    } else {
      units[i] += 1;
      return String.fromCharCodes(units);
    }
  }
  return '1${String.fromCharCodes(units)}';
}

/// Spells the [value] in Thai words using an abbreviated scale unit
/// (ล้าน / พันล้าน / ล้านล้าน …) when `|value| >= 10^6`.
///
/// For `|value| < 10^6` this falls back to [spell] (the full reading, no unit
/// word). The fractional part of the coefficient is read digit-by-digit after
/// `'จุด'`, exactly like [spellDecimal]. [decimals] (default 2) is the number
/// of fractional places kept, rounded half-away-from-zero with trailing zeros
/// trimmed; a whole coefficient drops the `'จุด'` entirely.
///
///     spellShort(1500000);       // 'หนึ่งจุดห้าล้าน'
///     spellShort(15000000);      // 'สิบห้าล้าน'
///     spellShort(2300000000);    // 'สองจุดสามพันล้าน'
///     spellShort(50000000000);   // 'ห้าสิบพันล้าน'
///     spellShort(-1500000);      // 'ลบหนึ่งจุดห้าล้าน'
///     spellShort(999999);        // 'เก้าแสนเก้าหมื่นเก้าพันเก้าร้อยเก้าสิบเก้า'
///
/// Throws [ArgumentError] if [decimals] is negative.
String spellShort(int value, {int decimals = 2}) =>
    spellShortBigInt(BigInt.from(value), decimals: decimals);

/// [BigInt] form of [spellShort]; works to arbitrary scale.
///
///     spellShortBigInt(BigInt.parse('1200000000000')); // 'หนึ่งจุดสองล้านล้าน'
///
/// Throws [ArgumentError] if [decimals] is negative.
String spellShortBigInt(BigInt value, {int decimals = 2}) {
  _checkDecimals(decimals);
  final neg = value.isNegative;
  final mag = value.abs();
  if (mag < _oneMillion) {
    return spellBigInt(value); // full reading, carries its own ลบ
  }
  final c = _resolve(mag.toString(), decimals);
  final unit = _unitWord(c.k);
  final intWords = spellBigInt(BigInt.parse(c.intPart));
  final b = StringBuffer();
  if (neg) b.write('ลบ');
  b.write(intWords);
  if (c.frac.isNotEmpty) {
    b.write('จุด');
    for (final ch in c.frac.codeUnits) {
      b.write(numberThai[ch - _asciiZeroCode]);
    }
  }
  b.write(unit);
  return b.toString();
}

/// Formats the [value] with an abbreviated scale unit and an Arabic-numeral
/// coefficient when `|value| >= 10^6`: `'1.5 ล้าน'`, `'2.3 พันล้าน'`,
/// `'50 พันล้าน'`. For `|value| < 10^6` this falls back to [formatInt] (the
/// grouped full number, no unit word).
///
/// [decimals] (default 2) is the number of fractional places kept, rounded
/// half-away-from-zero with trailing zeros trimmed. With [thaiDigits] `true`
/// only the ASCII digits of the coefficient become Thai numerals; the space and
/// the unit word are unchanged.
///
///     formatShort(1500000);                    // '1.5 ล้าน'
///     formatShort(15000000);                   // '15 ล้าน'
///     formatShort(1234567);                    // '1.23 ล้าน'
///     formatShort(2000000);                    // '2 ล้าน'
///     formatShort(50000000000);                // '50 พันล้าน'
///     formatShort(1500000, thaiDigits: true);  // '๑.๕ ล้าน'
///
/// Throws [ArgumentError] if [decimals] is negative.
String formatShort(int value, {int decimals = 2, bool thaiDigits = false}) =>
    formatShortBigInt(BigInt.from(value),
        decimals: decimals, thaiDigits: thaiDigits);

/// [BigInt] form of [formatShort]; works to arbitrary scale.
///
///     formatShortBigInt(BigInt.parse('1200000000000')); // '1.2 ล้านล้าน'
///
/// Throws [ArgumentError] if [decimals] is negative.
String formatShortBigInt(BigInt value,
    {int decimals = 2, bool thaiDigits = false}) {
  _checkDecimals(decimals);
  final neg = value.isNegative;
  final mag = value.abs();
  if (mag < _oneMillion) {
    // `.toInt()` cannot overflow here: this branch only runs when
    // |value| < 10^6, always within the int range (incl. the web 53-bit target).
    return formatInt(value.toInt(), thaiDigits: thaiDigits);
  }
  final c = _resolve(mag.toString(), decimals);
  final unit = _unitWord(c.k);
  var coeff = c.intPart;
  if (c.frac.isNotEmpty) coeff = '$coeff.${c.frac}';
  if (thaiDigits) coeff = toThaiDigits(coeff);
  return '${neg ? '-' : ''}$coeff $unit';
}

final BigInt _oneMillion = BigInt.from(1000000);

void _checkDecimals(int decimals) {
  if (decimals < 0) {
    throw ArgumentError.value(decimals, 'decimals', 'must be non-negative');
  }
}
