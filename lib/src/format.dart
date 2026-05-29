import 'numerals.dart';

final BigInt _hundred = BigInt.from(100);

/// Formats an integer with thousands separators: 1234567 -> "1,234,567".
///
/// When [thaiDigits] is true only the digits are rendered as Thai numerals
/// (`'๑,๒๓๔,๕๖๗'`); the commas and the `-` sign stay ASCII.
String formatInt(int n, {bool thaiDigits = false}) {
  final neg = n < 0;
  final s = _groupThousands(BigInt.from(n).abs().toString());
  final out = neg ? '-$s' : s;
  return thaiDigits ? toThaiDigits(out) : out;
}

/// Formats a satang amount as grouped baht with two decimals:
/// 2121 -> "21.21", 100000 -> "1,000.00".
///
/// When [thaiDigits] is true only the digits are rendered as Thai numerals
/// (`'๒๑.๒๑'`); the commas, decimal point and `-` sign stay ASCII.
String formatSatang(int satang, {bool thaiDigits = false}) {
  final neg = satang < 0;
  final mag = BigInt.from(satang).abs();
  final b = mag ~/ _hundred;
  final sat = (mag % _hundred).toInt();
  final body =
      '${_groupThousands(b.toString())}.${sat.toString().padLeft(2, '0')}';
  final out = neg ? '-$body' : body;
  return thaiDigits ? toThaiDigits(out) : out;
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
