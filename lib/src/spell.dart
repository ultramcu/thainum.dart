import 'exception.dart';
import 'numerals.dart';

/// Selects how a units digit 1 is read when it sits above a zero tens digit
/// (e.g. 101, 1001, 1,000,001). This is the one genuine convention split in
/// Thai number reading.
enum EtMode {
  /// Reads such a 1 as "เอ็ด" (101 -> หนึ่งร้อยเอ็ด). This is the Royal
  /// Institute's recommended form and the default.
  always,

  /// Reads such a 1 as "หนึ่ง" (101 -> หนึ่งร้อยหนึ่ง), using "เอ็ด" only when
  /// the tens digit is non-zero (11, 21, …).
  tensOnly,
}

const List<String> numberThai = [
  'ศูนย์',
  'หนึ่ง',
  'สอง',
  'สาม',
  'สี่',
  'ห้า',
  'หก',
  'เจ็ด',
  'แปด',
  'เก้า',
];

/// `placeWord[p]` is the Thai word for position p within a six-digit group:
/// 0=units, 1=tens, 2=hundreds, 3=thousands, 4=ten-thousands,
/// 5=hundred-thousands.
const List<String> _placeWord = ['', 'สิบ', 'ร้อย', 'พัน', 'หมื่น', 'แสน'];

const List<int> _pow10 = [1, 10, 100, 1000, 10000, 100000];

/// Renders the integer [n] as Thai words using the default [EtMode]
/// ([EtMode.always]).
///
///     spell(21);      // 'ยี่สิบเอ็ด'
///     spell(1000000); // 'หนึ่งล้าน'
///     spell(-5);      // 'ลบห้า'
String spell(int n) => const Speller().spellInt(n);

/// Renders an arbitrarily large integer as Thai words (default [EtMode]).
String spellBigInt(BigInt n) => const Speller().spellBigInt(n);

/// Renders a decimal number written as a string (e.g. "12.34") as Thai words:
/// the integer part is read normally, then "จุด", then each fractional digit
/// individually (12.34 -> "สิบสองจุดสามสี่"). A fractional part that is empty
/// or all zeros is dropped (100.00 -> "หนึ่งร้อย"). Uses the default [EtMode].
String spellDecimal(String s) => const Speller().spellDecimal(s);

/// Spells numbers as Thai words with a chosen [EtMode].
class Speller {
  /// Creates a speller using [et] for the trailing-one convention.
  const Speller({this.et = EtMode.always});

  /// How a trailing units 1 above a zero tens is read.
  final EtMode et;

  /// Renders the integer [n] as Thai words.
  String spellInt(int n) {
    if (n == 0) return numberThai[0];
    final neg = n < 0;
    // Use BigInt for the magnitude to handle the most-negative int safely.
    final mag = BigInt.from(n).abs();
    final out = _spellDigits(mag.toString());
    return neg ? 'ลบ$out' : out;
  }

  /// Renders an arbitrarily large integer as Thai words.
  String spellBigInt(BigInt n) {
    if (n.sign == 0) return numberThai[0];
    final mag = n.abs();
    final out = _spellDigits(mag.toString());
    return n.sign < 0 ? 'ลบ$out' : out;
  }

  /// Renders a decimal numeric string as Thai words.
  String spellDecimal(String s) {
    final d = _splitDecimal(s);
    String out;
    if (d.intPart.isEmpty || _isAllZero(d.intPart)) {
      out = numberThai[0]; // ศูนย์
    } else {
      out = _spellDigits(d.intPart);
    }
    if (d.frac.isNotEmpty && !_isAllZero(d.frac)) {
      final b = StringBuffer(out)..write('จุด');
      for (final ch in d.frac.codeUnits) {
        b.write(numberThai[ch - _asciiZeroCode]);
      }
      out = b.toString();
    }
    if (d.neg) out = 'ลบ$out';
    return out;
  }

  /// Spells a non-empty, non-negative integer digit string (no sign, leading
  /// zeros tolerated) as Thai words.
  String _spellDigits(String s) {
    s = _trimLeftZeros(s);
    if (s.isEmpty) return numberThai[0];
    final n = s.length;
    final numGroups = (n + 5) ~/ 6;

    final b = StringBuffer();
    var higherSeen = false;
    for (var gi = numGroups - 1; gi >= 0; gi--) {
      final end = n - gi * 6;
      var start = end - 6;
      if (start < 0) start = 0;
      final grp = s.substring(start, end);
      final gv = _atoiSmall(grp);
      if (gv == 0) continue;
      if (gi == 0 && gv == 1 && higherSeen) {
        // Trailing lone 1 after higher groups: cross-group เอ็ด rule.
        // Tens is zero here, so EtMode.tensOnly yields หนึ่ง.
        if (et == EtMode.always) {
          b.write('เอ็ด');
        } else {
          b.write(numberThai[1]);
        }
      } else {
        b.write(_spellGroup(gv));
      }
      for (var r = 0; r < gi; r++) {
        b.write('ล้าน');
      }
      higherSeen = true;
    }
    return b.toString();
  }

  /// Spells a value 1..999999 (a single six-digit group) as Thai words.
  /// Exposed for the baht module's satang rendering.
  String spellGroup(int n) => _spellGroup(n);

  /// Spells a value 1..999999 (a single six-digit group) as Thai words.
  String _spellGroup(int n) {
    final b = StringBuffer();
    final tens = (n ~/ 10) % 10;
    for (var p = 5; p >= 0; p--) {
      final d = (n ~/ _pow10[p]) % 10;
      if (d == 0) continue;
      switch (p) {
        case 1: // tens
          switch (d) {
            case 1:
              b.write('สิบ');
            case 2:
              b.write('ยี่สิบ');
            default:
              b.write('${numberThai[d]}สิบ');
          }
        case 0: // units
          if (d == 1 && n >= 10) {
            if (et == EtMode.always || tens != 0) {
              b.write('เอ็ด');
            } else {
              b.write(numberThai[1]);
            }
          } else {
            b.write(numberThai[d]);
          }
        default: // hundreds..hundred-thousands
          b.write('${numberThai[d]}${_placeWord[p]}');
      }
    }
    return b.toString();
  }
}

const int _asciiZeroCode = 0x30;

/// Parses a short digit string (<=6 chars) into an int.
int _atoiSmall(String s) {
  var v = 0;
  for (var i = 0; i < s.length; i++) {
    v = v * 10 + (s.codeUnitAt(i) - _asciiZeroCode);
  }
  return v;
}

String _trimLeftZeros(String s) {
  var i = 0;
  while (i < s.length && s.codeUnitAt(i) == _asciiZeroCode) {
    i++;
  }
  return s.substring(i);
}

bool _isAllZero(String s) {
  for (var i = 0; i < s.length; i++) {
    if (s.codeUnitAt(i) != _asciiZeroCode) return false;
  }
  return true;
}

bool isDigits(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c < 0x30 || c > 0x39) return false;
  }
  return true;
}

/// A parsed optionally-signed decimal numeric string.
class DecimalParts {
  DecimalParts(this.neg, this.intPart, this.frac);
  final bool neg;
  final String intPart;
  final String frac;
}

/// Parses an optionally-signed decimal numeric string into its sign, integer
/// digit part and fractional digit part. Surrounding spaces, a leading '+'/'-',
/// and Thai digits are accepted. Throws [ThaiNumException] on invalid input.
DecimalParts _splitDecimal(String s) {
  s = toArabicDigits(s).trim();
  if (s.isEmpty) {
    throw const ThaiNumException('thainum: empty number');
  }
  var neg = false;
  final first = s.codeUnitAt(0);
  if (first == 0x2D) {
    // '-'
    neg = true;
    s = s.substring(1);
  } else if (first == 0x2B) {
    // '+'
    s = s.substring(1);
  }
  var intPart = s;
  var frac = '';
  final dot = s.indexOf('.');
  if (dot >= 0) {
    intPart = s.substring(0, dot);
    frac = s.substring(dot + 1);
  }
  if (intPart.isEmpty && frac.isEmpty) {
    throw ThaiNumException('thainum: invalid number', s);
  }
  if (!isDigits(intPart) || !isDigits(frac)) {
    throw ThaiNumException('thainum: invalid number', s);
  }
  return DecimalParts(neg, intPart, frac);
}

/// Internal access to [_splitDecimal] for the baht module.
DecimalParts splitDecimalInternal(String s) => _splitDecimal(s);
