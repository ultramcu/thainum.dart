final BigInt _hundred = BigInt.from(100);

/// Formats an integer with thousands separators: 1234567 -> "1,234,567".
String formatInt(int n) {
  final neg = n < 0;
  final s = _groupThousands(BigInt.from(n).abs().toString());
  return neg ? '-$s' : s;
}

/// Formats a satang amount as grouped baht with two decimals:
/// 2121 -> "21.21", 100000 -> "1,000.00".
String formatSatang(int satang) {
  final neg = satang < 0;
  final mag = BigInt.from(satang).abs();
  final b = mag ~/ _hundred;
  final sat = (mag % _hundred).toInt();
  final out =
      '${_groupThousands(b.toString())}.${sat.toString().padLeft(2, '0')}';
  return neg ? '-$out' : out;
}

/// Formats a satang amount as Thai baht with the ฿ symbol:
/// 2121 -> "฿21.21".
String formatThb(int satang) {
  if (satang < 0) {
    return '-฿${formatSatang(-satang)}';
  }
  return '฿${formatSatang(satang)}';
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
