import 'exception.dart';
import 'numerals.dart';
import 'spell.dart' show numberThai, isDigits;

// Token kinds produced by the tokenizer.
enum _TokKind {
  digit, // a units digit 1..9 (ศูนย์..เก้า, ยี่, เอ็ด)
  zero, // ศูนย์
  place, // สิบ ร้อย พัน หมื่น แสน
  million, // ล้าน
  neg, // ลบ
}

class _Token {
  _Token(this.kind, this.text,
      {this.val = 0, this.yi = false, this.et = false});
  final _TokKind kind;
  final String text; // the matched source word (for error context)
  final int val; // digit value (digit) or place power-of-ten (place)
  final bool yi; // true if this digit came from ยี่ (only valid before สิบ)
  final bool et; // true if this digit came from เอ็ด (a trailing one)
}

class _WordEntry {
  _WordEntry(this.word, this.make);
  final String word;
  final _Token Function() make;
}

/// The dictionary of recognizable words, sorted by descending length so a
/// greedy longest-match tokenizer is correct.
final List<_WordEntry> _numberWords = _buildWordTable();

List<_WordEntry> _buildWordTable() {
  final t = <_WordEntry>[
    // sign
    _WordEntry('ลบ', () => _Token(_TokKind.neg, 'ลบ')),
    // special digits
    _WordEntry('ยี่', () => _Token(_TokKind.digit, 'ยี่', val: 2, yi: true)),
    _WordEntry('เอ็ด', () => _Token(_TokKind.digit, 'เอ็ด', val: 1, et: true)),
    // place / multiplier words
    _WordEntry('ล้าน', () => _Token(_TokKind.million, 'ล้าน', val: 1000000)),
    _WordEntry('แสน', () => _Token(_TokKind.place, 'แสน', val: 100000)),
    _WordEntry('หมื่น', () => _Token(_TokKind.place, 'หมื่น', val: 10000)),
    _WordEntry('พัน', () => _Token(_TokKind.place, 'พัน', val: 1000)),
    _WordEntry('ร้อย', () => _Token(_TokKind.place, 'ร้อย', val: 100)),
    _WordEntry('สิบ', () => _Token(_TokKind.place, 'สิบ', val: 10)),
  ];
  // digit words 0..9
  for (var d = 0; d < 10; d++) {
    final w = numberThai[d];
    if (d == 0) {
      t.add(_WordEntry(w, () => _Token(_TokKind.zero, w, val: 0)));
    } else {
      final dv = d;
      t.add(_WordEntry(w, () => _Token(_TokKind.digit, w, val: dv)));
    }
  }
  // sort by descending word length for greedy longest-match
  t.sort((a, b) => b.word.length.compareTo(a.word.length));
  return t;
}

/// Parses Thai number words into an int.
///
///     parseInt('ยี่สิบเอ็ด'); // 21
///     parseInt('หนึ่งล้าน');  // 1000000
///     parseInt('ลบห้า');      // -5
///     parseInt('ศูนย์');      // 0
///
/// Thai or Arabic digit characters are also accepted (parseInt('๒๑') == 21).
/// Values that overflow [int] throw a [ThaiNumException] suggesting [parseBigInt].
int parseInt(String words) {
  final b = parseBigInt(words);
  if (!b.isValidInt) {
    throw ThaiNumException(
      'thainum: value $b overflows int (use parseBigInt)',
      words,
    );
  }
  return b.toInt();
}

/// Parses Thai number words into an arbitrary-precision integer.
///
///     parseBigInt('หนึ่งล้านล้าน');      // 10^12
///     parseBigInt('หนึ่งล้านล้านล้าน');  // 10^18
BigInt parseBigInt(String words) {
  var s = toArabicDigits(words).trim();
  if (s.isEmpty) {
    throw const ThaiNumException('thainum: empty input');
  }

  // Allow a plain numeric string (already converted from Thai digits above):
  // an optional sign followed by ASCII digits.
  final plain = _parsePlainDigits(s);
  if (plain != null) return plain;

  var neg = false;
  if (s.startsWith('ลบ')) {
    neg = true;
    s = s.substring('ลบ'.length);
    if (s.isEmpty) {
      throw const ThaiNumException('thainum: "ลบ" is not a number', 'ลบ');
    }
  }

  final toks = _tokenize(s);
  var v = _evalTokens(toks);
  if (neg) v = -v;
  return v;
}

/// Handles a purely-numeric input (optionally signed). Returns null when the
/// string is not purely numeric so the word parser can take over.
BigInt? _parsePlainDigits(String s) {
  var t = s;
  if (t.startsWith('+') || t.startsWith('-')) {
    t = t.substring(1);
  }
  if (t.isEmpty || !isDigits(t)) return null;
  return BigInt.tryParse(s);
}

/// Splits a sign-free Thai number string into recognized tokens using a greedy
/// longest-match scan. An unrecognized run throws [ThaiNumException].
List<_Token> _tokenize(String s) {
  final toks = <_Token>[];
  while (s.isNotEmpty) {
    var matched = false;
    for (final e in _numberWords) {
      if (s.startsWith(e.word)) {
        toks.add(e.make());
        s = s.substring(e.word.length);
        matched = true;
        break;
      }
    }
    if (!matched) {
      // Report the next characters as the unknown token for context.
      final runes = s.runes.toList();
      final n = runes.length < 4 ? runes.length : 4;
      final bad = String.fromCharCodes(runes.sublist(0, n));
      throw ThaiNumException('thainum: unknown token', bad);
    }
  }
  return toks;
}

final BigInt _million = BigInt.from(1000000);

/// Runs the accumulator state machine over the tokens.
///
/// Thai writes large numbers in six-digit groups separated by ล้าน (10^6), and
/// the higher groups stack the word — ล้านล้าน is 10^12, ล้านล้านล้าน is 10^18,
/// and so on. So a group followed by k consecutive ล้าน contributes
/// group * 10^(6k). The million-run lengths must strictly decrease from one
/// group to the next, otherwise the input is malformed.
BigInt _evalTokens(List<_Token> toks) {
  var result = BigInt.zero;
  var current = BigInt.zero;

  var pending = -1; // -1 means "no pending digit"
  var pendingYi = false; // pending digit came from ยี่

  // maxPlaceInGroup rejects repeated/ascending places within a group.
  var maxPlaceInGroup = 0;
  var curHasContent = false; // current group has received any value

  // lastMillionPower is the ล้าน-run length of the previously flushed group;
  // runs must strictly decrease. -1 means no group has been flushed yet.
  var lastMillionPower = -1;

  void flushPendingAsUnits() {
    if (pending < 0) return;
    if (pendingYi) {
      // ยี่ is only valid immediately before สิบ.
      throw const ThaiNumException(
          'thainum: "ยี่" must be followed by สิบ', 'ยี่');
    }
    current += BigInt.from(pending);
    curHasContent = true;
    pending = -1;
  }

  for (var i = 0; i < toks.length; i++) {
    final tk = toks[i];
    switch (tk.kind) {
      case _TokKind.neg:
        throw ThaiNumException('thainum: misplaced word', tk.text);

      case _TokKind.zero:
        // ศูนย์ is only meaningful as the entire value. Inside a compound it is
        // malformed.
        if (toks.length == 1) {
          return BigInt.zero;
        }
        throw ThaiNumException('thainum: misplaced word', tk.text);

      case _TokKind.digit:
        if (pending >= 0) {
          throw ThaiNumException('thainum: two digits in a row', tk.text);
        }
        pending = tk.val;
        pendingYi = tk.yi;
        if (tk.et) {
          // เอ็ด is a trailing one; it must terminate a group (it cannot take a
          // place word).
          if (i + 1 < toks.length) {
            final nxt = toks[i + 1];
            if (nxt.kind == _TokKind.place) {
              throw ThaiNumException(
                'thainum: "เอ็ด" cannot precede a place word',
                tk.text,
              );
            }
          }
          current += BigInt.one;
          curHasContent = true;
          pending = -1;
          pendingYi = false;
        }

      case _TokKind.place:
        final place = tk.val;
        var digit = 1;
        var isYi = false;
        if (pending >= 0) {
          digit = pending;
          isYi = pendingYi;
          pending = -1;
          pendingYi = false;
        }
        // ยี่ is only valid directly before สิบ (ยี่สิบ = 20).
        if (isYi && place != 10) {
          throw const ThaiNumException(
            'thainum: "ยี่" must be followed by สิบ',
            'ยี่',
          );
        }
        // Enforce strictly descending places within a group.
        if (curHasContent && place >= maxPlaceInGroup) {
          throw ThaiNumException('thainum: misplaced place word', tk.text);
        }
        current += BigInt.from(digit) * BigInt.from(place);
        curHasContent = true;
        maxPlaceInGroup = place;

      case _TokKind.million:
        // Flush any pending units digit into the current group first.
        flushPendingAsUnits();
        if (!curHasContent) {
          // A bare ล้าน reads as 1,000,000.
          current = BigInt.one;
          curHasContent = true;
        }
        // Count this and any directly-following ล้าน tokens as one run.
        var power = 1;
        while (i + 1 < toks.length && toks[i + 1].kind == _TokKind.million) {
          power++;
          i++;
        }
        if (lastMillionPower >= 0 && power >= lastMillionPower) {
          throw const ThaiNumException('thainum: ล้าน groups out of order');
        }
        lastMillionPower = power;
        // result += current * 10^(6*power)
        final scale = _million.pow(power);
        result += current * scale;
        current = BigInt.zero;
        curHasContent = false;
        maxPlaceInGroup = 0;
    }
  }

  flushPendingAsUnits();
  result += current;
  return result;
}

/// Parses Thai Baht text into an integer satang amount.
///
///     parseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'); // 2121
///     parseBaht('หนึ่งร้อยบาทถ้วน');             // 10000
///     parseBaht('ศูนย์บาทถ้วน');                 // 0
///     parseBaht('ยี่สิบห้าสตางค์');              // 25
///     parseBaht('ลบหนึ่งบาทหนึ่งสตางค์');        // -101
int parseBaht(String text) {
  var s = toArabicDigits(text).trim();
  if (s.isEmpty) {
    throw const ThaiNumException('thainum: empty input');
  }

  var neg = false;
  if (s.startsWith('ลบ')) {
    neg = true;
    s = s.substring('ลบ'.length);
  }

  // Drop a trailing ถ้วน ("exactly", no satang).
  if (s.endsWith('ถ้วน')) {
    s = s.substring(0, s.length - 'ถ้วน'.length);
  }

  var bahtPart = '';
  var satPart = '';

  final idx = s.indexOf('บาท');
  if (idx >= 0) {
    bahtPart = s.substring(0, idx);
    var rest = s.substring(idx + 'บาท'.length);
    if (rest.endsWith('สตางค์')) {
      rest = rest.substring(0, rest.length - 'สตางค์'.length);
    }
    satPart = rest;
  } else if (s.endsWith('สตางค์')) {
    // Satang-only amount, e.g. "ยี่สิบห้าสตางค์".
    satPart = s.substring(0, s.length - 'สตางค์'.length);
  } else {
    bahtPart = s;
  }

  var bahtVal = 0;
  if (bahtPart.trim().isNotEmpty) {
    try {
      bahtVal = parseInt(bahtPart);
    } on ThaiNumException catch (e) {
      throw ThaiNumException('${e.message} (baht part)', e.source, e.offset);
    }
  }

  var satVal = 0;
  if (satPart.trim().isNotEmpty) {
    int sv;
    try {
      sv = parseInt(satPart);
    } on ThaiNumException catch (e) {
      throw ThaiNumException('${e.message} (satang part)', e.source, e.offset);
    }
    if (sv < 0 || sv > 99) {
      throw ThaiNumException('thainum: satang $sv out of range 0..99', text);
    }
    satVal = sv;
  }

  var total = bahtVal * 100 + satVal;
  if (neg) total = -total;
  return total;
}

/// Like [parseInt] but returns `null` instead of throwing when [s] is not a
/// valid Thai number (or overflows `int`).
///
///     tryParseInt('ยี่สิบเอ็ด'); // 21
///     tryParseInt('สิบสิบ');     // null
int? tryParseInt(String s) {
  try {
    return parseInt(s);
  } on FormatException {
    return null;
  }
}

/// Like [parseBigInt] but returns `null` instead of throwing when [s] is not a
/// valid Thai number.
///
///     tryParseBigInt('หนึ่งล้านล้าน'); // 10^12
///     tryParseBigInt('ร้อยพัน');       // null
BigInt? tryParseBigInt(String s) {
  try {
    return parseBigInt(s);
  } on FormatException {
    return null;
  }
}

/// Like [parseBaht] but returns `null` instead of throwing when [s] is not a
/// valid Thai baht text (or has out-of-range satang).
///
///     tryParseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'); // 2121
///     tryParseBaht('');                                // null
int? tryParseBaht(String s) {
  try {
    return parseBaht(s);
  } on FormatException {
    return null;
  }
}
