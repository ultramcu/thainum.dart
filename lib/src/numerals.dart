// Thai digits ๐..๙ occupy the contiguous Unicode range U+0E50..U+0E59.
const int _thaiZero = 0x0E50; // ๐
const int _thaiNine = 0x0E59; // ๙
const int _asciiZero = 0x30; // 0
const int _asciiNine = 0x39; // 9

/// Replaces every ASCII digit 0-9 in [s] with its Thai numeral (๐-๙),
/// leaving all other characters untouched.
///
///     toThaiDigits('Room 101'); // 'Room ๑๐๑'
String toThaiDigits(String s) {
  final buf = StringBuffer();
  for (final r in s.runes) {
    if (r >= _asciiZero && r <= _asciiNine) {
      buf.writeCharCode(_thaiZero + (r - _asciiZero));
    } else {
      buf.writeCharCode(r);
    }
  }
  return buf.toString();
}

/// Replaces every Thai numeral ๐-๙ in [s] with its ASCII digit 0-9,
/// leaving all other characters untouched.
///
///     toArabicDigits('ห้อง ๑๐๑'); // 'ห้อง 101'
String toArabicDigits(String s) {
  final buf = StringBuffer();
  for (final r in s.runes) {
    if (r >= _thaiZero && r <= _thaiNine) {
      buf.writeCharCode(_asciiZero + (r - _thaiZero));
    } else {
      buf.writeCharCode(r);
    }
  }
  return buf.toString();
}
