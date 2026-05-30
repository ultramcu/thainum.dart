import 'numerals.dart';

final BigInt _hundred = BigInt.from(100);

// Code units shared by the native-int formatter's buffer builder.
const int _ch0 = 0x30; // '0'
const int _chComma = 0x2C; // ','
const int _chMinus = 0x2D; // '-'
const int _chDot = 0x2E; // '.'
const int _thaiZeroCode = 0x0E50; // '๐'

/// Formats an integer with thousands separators: 1234567 -> "1,234,567".
///
/// When [thaiDigits] is true only the digits are rendered as Thai numerals
/// (`'๑,๒๓๔,๕๖๗'`); the commas and the `-` sign stay ASCII.
String formatInt(int n, {bool thaiDigits = false}) {
  // int.minValue has no positive magnitude as a native int — negating it
  // overflows back to itself (still negative) — so fall back to the BigInt path
  // for it; everything else stays on the fast native path. Detected via that
  // overflow rather than a 64-bit literal, so this also compiles to the web
  // (dart2js cannot represent the 0x7FFFFFFFFFFFFFFF literal).
  if (n < 0 && -n < 0) {
    final s = _groupThousands(BigInt.from(n).abs().toString());
    final out = '-$s';
    return thaiDigits ? toThaiDigits(out) : out;
  }
  final neg = n < 0;
  final mag = neg ? -n : n;
  final zeroCode = thaiDigits ? _thaiZeroCode : _ch0;
  return _groupedIntString(mag, neg, zeroCode);
}

/// Builds "[-]d,ddd,ddd" for a non-negative native int [mag] directly into a
/// code-unit buffer (no BigInt, no intermediate substring/StringBuffer).
/// [zeroCode] selects ASCII ('0') or Thai ('๐') digit glyphs; commas/sign stay
/// ASCII either way (matching the `thaiDigits` contract).
String _groupedIntString(int mag, bool neg, int zeroCode) {
  // Count decimal digits.
  var nDigits = 1;
  var t = mag;
  while (t >= 10) {
    nDigits++;
    t ~/= 10;
  }
  final nCommas = (nDigits - 1) ~/ 3;
  final total = nDigits + nCommas + (neg ? 1 : 0);
  final out = List<int>.filled(total, 0);
  var w = total - 1;
  var sinceComma = 0;
  var v = mag;
  for (var k = 0; k < nDigits; k++) {
    if (sinceComma == 3) {
      out[w--] = _chComma;
      sinceComma = 0;
    }
    out[w--] = zeroCode + (v % 10);
    v ~/= 10;
    sinceComma++;
  }
  if (neg) out[w--] = _chMinus;
  return String.fromCharCodes(out);
}

/// Formats a satang amount as grouped baht with two decimals:
/// 2121 -> "21.21", 100000 -> "1,000.00".
///
/// When [thaiDigits] is true only the digits are rendered as Thai numerals
/// (`'๒๑.๒๑'`); the commas, decimal point and `-` sign stay ASCII.
String formatSatang(int satang, {bool thaiDigits = false}) {
  // int.minValue (negating it overflows back to itself) — see formatInt.
  if (satang < 0 && -satang < 0) {
    // Rare overflow case: keep the exact BigInt arithmetic.
    final mag = BigInt.from(satang).abs();
    final b = mag ~/ _hundred;
    final sat = (mag % _hundred).toInt();
    final body =
        '${_groupThousands(b.toString())}.${sat.toString().padLeft(2, '0')}';
    final out = '-$body';
    return thaiDigits ? toThaiDigits(out) : out;
  }
  final neg = satang < 0;
  final mag = neg ? -satang : satang;
  final baht = mag ~/ 100;
  final sat = mag % 100;
  final zeroCode = thaiDigits ? _thaiZeroCode : _ch0;
  return _groupedSatangString(baht, sat, neg, zeroCode);
}

/// Builds "[-]b,bbb.ss" directly into a code-unit buffer. [sat] is 0..99.
String _groupedSatangString(int baht, int sat, bool neg, int zeroCode) {
  var nDigits = 1;
  var t = baht;
  while (t >= 10) {
    nDigits++;
    t ~/= 10;
  }
  final nCommas = (nDigits - 1) ~/ 3;
  // baht digits + commas + '.' + 2 satang digits + optional sign
  final total = nDigits + nCommas + 3 + (neg ? 1 : 0);
  final out = List<int>.filled(total, 0);
  var w = total - 1;
  // Two satang digits (always two, zero-padded).
  out[w--] = zeroCode + (sat % 10);
  out[w--] = zeroCode + (sat ~/ 10);
  out[w--] = _chDot;
  var sinceComma = 0;
  var v = baht;
  for (var k = 0; k < nDigits; k++) {
    if (sinceComma == 3) {
      out[w--] = _chComma;
      sinceComma = 0;
    }
    out[w--] = zeroCode + (v % 10);
    v ~/= 10;
    sinceComma++;
  }
  if (neg) out[w--] = _chMinus;
  return String.fromCharCodes(out);
}

/// Formats a satang amount as Thai baht with the ฿ symbol:
/// 2121 -> "฿21.21".
///
/// When [thaiDigits] is true only the digits are rendered as Thai numerals
/// (`'฿๒๑.๒๑'`); the `฿` symbol, commas, decimal point and `-` sign stay ASCII.
String formatThb(int satang, {bool thaiDigits = false}) {
  if (satang < 0) {
    return '-฿${formatSatang(-satang, thaiDigits: thaiDigits)}';
  }
  return '฿${formatSatang(satang, thaiDigits: thaiDigits)}';
}

/// Inserts commas every three digits into a plain digit string.
String _groupThousands(String s) {
  final n = s.length;
  if (n <= 3) return s;
  final b = StringBuffer();
  final pre = n % 3;
  if (pre > 0) {
    b.write(s.substring(0, pre));
  }
  for (var i = pre; i < n; i += 3) {
    if (b.length > 0) b.write(',');
    b.write(s.substring(i, i + 3));
  }
  return b.toString();
}
