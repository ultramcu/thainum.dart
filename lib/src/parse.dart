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

/// The strict dictionary of recognizable words, sorted by descending length so
/// a greedy longest-match tokenizer is correct.
final List<_WordEntry> _numberWords = _buildWordTable(allowColloquial: false);

/// The dictionary extended with colloquial words (currently `'นึง'` for 1).
final List<_WordEntry> _numberWordsColloquial =
    _buildWordTable(allowColloquial: true);

/// Returns the word table to use for the given [allowColloquial] flag.
List<_WordEntry> _wordTable(bool allowColloquial) =>
    allowColloquial ? _numberWordsColloquial : _numberWords;

List<_WordEntry> _buildWordTable({required bool allowColloquial}) {
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
  if (allowColloquial) {
    // 'นึง' is the spoken contraction of หนึ่ง (one). Read like a trailing one
    // so 'ร้อยนึง' parses as 101.
    t.add(_WordEntry('นึง', () => _Token(_TokKind.digit, 'นึง', val: 1)));
  }
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

const String _nbsp = ' '; // non-breaking space
const String _zwsp = '​'; // zero-width space

/// Removes internal ASCII spaces, NBSP and zero-width characters from [s].
/// Used by the lenient parse path so spaced-out input still tokenizes.
String _normalizeLenient(String s) =>
    s.replaceAll(' ', '').replaceAll(_nbsp, '').replaceAll(_zwsp, '');

/// Parses Thai number words into an int.
///
///     parseInt('ยี่สิบเอ็ด'); // 21
///     parseInt('หนึ่งล้าน');  // 1000000
///     parseInt('ลบห้า');      // -5
///     parseInt('ศูนย์');      // 0
///
/// Thai or Arabic digit characters are also accepted (parseInt('๒๑') == 21).
/// Values that overflow [int] throw a [ThaiNumException] suggesting [parseBigInt].
///
/// Set [allowColloquial] to also accept `'นึง'` as 1
/// (`parseInt('ร้อยนึง', allowColloquial: true)` → 101). Set [lenient] to strip
/// internal ASCII spaces, NBSP (U+00A0) and zero-width characters (U+200B)
/// before parsing (`parseInt('ยี่สิบ เอ็ด', lenient: true)` → 21). Both default
/// to false, leaving the strict path byte-for-byte unchanged.
int parseInt(String words,
    {bool allowColloquial = false, bool lenient = false}) {
  final b =
      parseBigInt(words, allowColloquial: allowColloquial, lenient: lenient);
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
///
/// See [parseInt] for the [allowColloquial] and [lenient] options.
BigInt parseBigInt(String words,
    {bool allowColloquial = false, bool lenient = false}) {
  var s = toArabicDigits(words).trim();
  if (lenient) s = _normalizeLenient(s);
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

  final toks = _tokenize(s, _wordTable(allowColloquial));
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
/// longest-match scan against [table]. An unrecognized run throws
/// [ThaiNumException].
List<_Token> _tokenize(String s, List<_WordEntry> table) {
  final toks = <_Token>[];
  while (s.isNotEmpty) {
    var matched = false;
    for (final e in table) {
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

/// Tries to match a single number word from [table] at the start of [s].
/// Returns the matched [_WordEntry] (whose `.word.length` gives the consumed
/// length) or null if no word matches there.
_WordEntry? _matchWordAt(String s, List<_WordEntry> table) {
  for (final e in table) {
    if (s.startsWith(e.word)) return e;
  }
  return null;
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
///
/// See [parseInt] for the [allowColloquial] and [lenient] options.
int parseBaht(String text,
    {bool allowColloquial = false, bool lenient = false}) {
  var s = toArabicDigits(text).trim();
  // `lenient` normalizes the whole string here (before the บาท/สตางค์ split), so
  // the baht/satang parts are already space-free — the inner parseInt calls
  // below only need to forward `allowColloquial`, not `lenient`.
  if (lenient) s = _normalizeLenient(s);
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
      bahtVal = parseInt(bahtPart, allowColloquial: allowColloquial);
    } on ThaiNumException catch (e) {
      throw ThaiNumException('${e.message} (baht part)', e.source, e.offset);
    }
  }

  var satVal = 0;
  if (satPart.trim().isNotEmpty) {
    int sv;
    try {
      sv = parseInt(satPart, allowColloquial: allowColloquial);
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

/// Maps each single-digit word (ศูนย์..เก้า) to its value, for reading a
/// fractional part digit-by-digit.
final Map<String, int> _fracDigitWords = () {
  final m = <String, int>{};
  for (var d = 0; d < 10; d++) {
    m[numberThai[d]] = d;
  }
  return m;
}();

/// Parses Thai decimal words into a canonical decimal string — the inverse of
/// `spellDecimal`.
///
///     parseDecimal('สิบสองจุดสามสี่'); // '12.34'
///     parseDecimal('ศูนย์จุดห้า');      // '0.5'
///     parseDecimal('ลบสามจุดหนึ่งสี่'); // '-3.14'
///     parseDecimal('ยี่สิบเอ็ด');       // '21'  (no จุด → integer string)
///
/// The text is split on `'จุด'`: the integer part is read with the integer
/// parser; the fractional part is a run of single-digit words (ศูนย์..เก้า),
/// each read individually and concatenated as digits. A leading `'ลบ'` makes
/// the result negative. The return value is a canonical decimal **String** (so
/// precision and leading/trailing zeros from the input are preserved exactly).
///
/// Throws [ThaiNumException] if the fractional part contains anything that is
/// not a bare single-digit word, or if there is more than one `'จุด'`.
///
/// See [parseInt] for the [allowColloquial] and [lenient] options (they apply
/// to the integer part).
String parseDecimal(String words,
    {bool allowColloquial = false, bool lenient = false}) {
  var s = toArabicDigits(words).trim();
  if (lenient) s = _normalizeLenient(s);
  if (s.isEmpty) {
    throw const ThaiNumException('thainum: empty input');
  }

  var neg = false;
  if (s.startsWith('ลบ')) {
    neg = true;
    s = s.substring('ลบ'.length);
    if (s.isEmpty) {
      throw const ThaiNumException('thainum: "ลบ" is not a number', 'ลบ');
    }
  }

  final dotIdx = s.indexOf('จุด');
  if (dotIdx < 0) {
    // No fractional part: behave like the integer parser.
    final v = parseBigInt(s, allowColloquial: allowColloquial);
    return (neg ? -v : v).toString();
  }

  final intStr = s.substring(0, dotIdx);
  var fracStr = s.substring(dotIdx + 'จุด'.length);
  if (fracStr.contains('จุด')) {
    throw ThaiNumException('thainum: more than one "จุด"', words);
  }
  if (fracStr.isEmpty) {
    throw ThaiNumException(
        'thainum: missing fractional part after "จุด"', words);
  }

  // The integer part may be empty only via an explicit ศูนย์; an empty string
  // before จุด is malformed.
  final BigInt intVal;
  if (intStr.isEmpty) {
    throw ThaiNumException('thainum: missing integer part before "จุด"', words);
  } else {
    intVal = parseBigInt(intStr, allowColloquial: allowColloquial);
  }

  // Read each fractional digit word individually.
  final frac = StringBuffer();
  while (fracStr.isNotEmpty) {
    String? best;
    for (final w in _fracDigitWords.keys) {
      if (fracStr.startsWith(w) && (best == null || w.length > best.length)) {
        best = w;
      }
    }
    if (best == null) {
      final runes = fracStr.runes.toList();
      final n = runes.length < 4 ? runes.length : 4;
      final bad = String.fromCharCodes(runes.sublist(0, n));
      throw ThaiNumException('thainum: invalid fractional digit word', bad);
    }
    frac.write(_fracDigitWords[best]);
    fracStr = fracStr.substring(best.length);
  }

  final sign = neg ? '-' : '';
  return '$sign$intVal.${frac.toString()}';
}

/// A single number found embedded in free text by [extractNumbers].
class NumberMatch {
  /// Creates a [NumberMatch]. [start]/[end] are code-unit offsets into the
  /// source string passed to [extractNumbers].
  const NumberMatch({
    required this.start,
    required this.end,
    required this.matched,
    required this.value,
    required this.isWord,
    required this.isDigits,
  });

  /// Start index (inclusive) into the source string.
  final int start;

  /// End index (exclusive) into the source string. `text.substring(start, end)`
  /// equals [matched].
  final int end;

  /// The exact matched substring of the source.
  final String matched;

  /// The numeric value of the match.
  final BigInt value;

  /// True when the match came from Thai number words.
  final bool isWord;

  /// True when the match came from Arabic/Thai digit characters.
  final bool isDigits;

  @override
  String toString() => 'NumberMatch($start..$end "$matched" = $value, '
      'isWord: $isWord, isDigits: $isDigits)';
}

const int _asciiZeroCode = 0x30;
const int _asciiNineCode = 0x39;
const int _thaiZeroCode = 0x0E50;
const int _thaiNineCode = 0x0E59;

bool _isDigitRune(int r) =>
    (r >= _asciiZeroCode && r <= _asciiNineCode) ||
    (r >= _thaiZeroCode && r <= _thaiNineCode);

/// Finds every Thai number embedded in free [text], left to right.
///
///     extractNumbers('ซื้อมา ๓ ชิ้น ราคาห้าร้อยบาท');
///     // [ ๓ → 3 (isDigits), ห้าร้อย → 500 (isWord) ]
///
/// At each position it consumes the **maximal valid number** starting there:
/// either a run of digit characters (Arabic `0-9` and/or Thai `๐-๙`, emitted
/// as one digits-match) or a maximal run of contiguous number **words** that
/// the integer grammar accepts as a single number.
///
/// **Maximal-munch rule for word runs (deterministic):** starting at a number
/// word, greedily append the next contiguous number-word token while the whole
/// accumulated token sequence still parses as a valid integer. Stop at the
/// first token that is not a number word, or that would make the sequence
/// invalid. Emit the **longest valid prefix** as a single match, then resume
/// scanning immediately after that match. If a position can start no valid
/// number, advance by one code unit. As a consequence, `'ยี่สิบเอ็ด'` yields
/// one match (21, not 20 then 1), and a sequence like `'ห้าร้อยสิบสิบ'` yields
/// the longest valid prefix `'ห้าร้อยสิบ'` (510) followed by `'สิบ'` (10),
/// because appending the second `สิบ` makes the run invalid.
///
/// `'ลบ'` (minus) is treated as a non-number connector here and is not part of
/// a match, so extracted values are non-negative magnitudes.
List<NumberMatch> extractNumbers(String text) {
  final matches = <NumberMatch>[];
  // Work in Arabic-normalized space for value computation, but the table match
  // works on the original characters since digits normalize 1:1 by code unit.
  var i = 0;
  final len = text.length;
  while (i < len) {
    final r = text.codeUnitAt(i);

    // 1) Digit run (Arabic and/or Thai digits).
    if (_isDigitRune(r)) {
      var j = i;
      final buf = StringBuffer();
      while (j < len && _isDigitRune(text.codeUnitAt(j))) {
        final c = text.codeUnitAt(j);
        final d = (c >= _thaiZeroCode) ? c - _thaiZeroCode : c - _asciiZeroCode;
        buf.write(d);
        j++;
      }
      matches.add(NumberMatch(
        start: i,
        end: j,
        matched: text.substring(i, j),
        value: BigInt.parse(buf.toString()),
        isWord: false,
        isDigits: true,
      ));
      i = j;
      continue;
    }

    // 2) Word run: try to match a number word at i.
    final firstWord = _matchWordAt(text.substring(i), _numberWords);
    if (firstWord == null || firstWord.make().kind == _TokKind.neg) {
      // 'ลบ' alone is not a number start here; advance one code unit.
      i++;
      continue;
    }

    // Greedily collect word tokens, tracking the longest prefix that parses.
    var scan = i;
    var bestEnd = -1; // exclusive end of the longest valid prefix
    BigInt bestVal = BigInt.zero;
    final toks = <_Token>[];
    while (scan < len) {
      final e = _matchWordAt(text.substring(scan), _numberWords);
      if (e == null) break;
      final tk = e.make();
      if (tk.kind == _TokKind.neg) break; // a sign cannot extend a number
      toks.add(tk);
      scan += e.word.length;
      // Try to evaluate the accumulated token run as a complete number.
      try {
        final v = _evalTokens(List<_Token>.of(toks));
        bestEnd = scan;
        bestVal = v;
      } on ThaiNumException {
        // Not (yet) a valid number; keep extending — a later token may close
        // it, e.g. a lone digit followed by a place word.
      }
    }

    if (bestEnd > i) {
      matches.add(NumberMatch(
        start: i,
        end: bestEnd,
        matched: text.substring(i, bestEnd),
        value: bestVal,
        isWord: true,
        isDigits: false,
      ));
      i = bestEnd;
    } else {
      i++;
    }
  }
  return matches;
}
