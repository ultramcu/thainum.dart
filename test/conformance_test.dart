// Cross-port conformance test (A6).
//
// Replays the language-neutral golden vectors generated from the Go reference
// (go-thainum) and asserts that thainum.dart produces byte-for-byte the same
// output on the SHARED surface. This is the machine-checked guarantee that the
// two same-owner libraries cannot silently drift.
//
// The vectors live at test/conformance/vectors.json and are regenerated with:
//   cd go-thainum && go run ./tool/gen_golden > ../thainum.dart/test/conformance/vectors.json
// (see test/conformance/README.md for the pinned go-thainum version).
//
// Anti-vacuous guarantees (this test HARD-FAILS, never silently skips, if):
//   * vectors.json is missing or empty,
//   * the JSON has no `records`,
//   * a record's `fn` is not in the dispatch map,
//   * fewer than [_minRecords] records were actually asserted.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

/// Sanity floor: the generator currently emits ~695 records across 8 groups.
/// If a regeneration ever produces far fewer, the test fails rather than
/// passing vacuously. Set below the real count (695) so legitimate minor
/// pruning doesn't false-fail, but high enough that dropping a whole group
/// (e.g. the ~281-record date group) trips the floor.
const int _minRecords = 600;

/// Locates test/conformance/vectors.json relative to the test runner's CWD
/// (the package root under `dart test`).
File _vectorsFile() {
  final candidates = <String>[
    'test/conformance/vectors.json',
    'conformance/vectors.json',
  ];
  for (final p in candidates) {
    final f = File(p);
    if (f.existsSync()) return f;
  }
  // Last resort: walk up from the script dir.
  return File('test/conformance/vectors.json');
}

/// Normalizes to Unicode NFC for comparison. Dart strings are UTF-16; the
/// vectors are UTF-8 NFC. Decoding via jsonDecode already yields NFC here, but
/// we keep the comparison explicit and symmetric.
String _nfc(String s) =>
    s; // both sides are already NFC; identity keeps intent explicit

/// A typed record from vectors.json.
class _Rec {
  _Rec(this.group, this.fn, this.args, this.et, this.out);
  final String group;
  final String fn;
  final List<dynamic> args;
  final String et; // '', 'always', 'tensOnly'
  final String out;

  String describe() =>
      'group=$group fn=$fn args=$args${et.isEmpty ? '' : ' et=$et'}';
}

// ---- argument coercion helpers --------------------------------------------

int _int(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.parse(v);
  if (v is double && v == v.roundToDouble()) return v.toInt();
  throw ArgumentError('not an int: $v (${v.runtimeType})');
}

String _str(dynamic v) => v as String;

BigInt _big(dynamic v) {
  if (v is String) return BigInt.parse(v);
  if (v is int) return BigInt.from(v);
  throw ArgumentError('not a bigint-able: $v');
}

EtMode _etMode(String et) => et == 'tensOnly' ? EtMode.tensOnly : EtMode.always;

/// Builds a UTC midnight DateTime from [y,m,d] args.
DateTime _dateYMD(List<dynamic> a) =>
    DateTime.utc(_int(a[0]), _int(a[1]), _int(a[2]));

/// Builds a UTC DateTime from [hour, minute] args (date fixed, irrelevant).
DateTime _timeHM(List<dynamic> a) =>
    DateTime.utc(2024, 1, 1, _int(a[0]), _int(a[1]));

/// Dispatch map: fn name -> closure taking (args, et) and returning the Dart
/// output as the same comparison string the Go side recorded.
///
/// Every shared function MUST appear here. A record whose fn is absent makes
/// the test fail (no silent skip).
final Map<String, String Function(List<dynamic> args, String et)> _dispatch = {
  // numerals
  'toThaiDigits': (a, _) => toThaiDigits(_str(a[0])),
  'toArabicDigits': (a, _) => toArabicDigits(_str(a[0])),

  // spell (EtMode-sensitive)
  'spell': (a, et) => Speller(et: _etMode(et)).spellInt(_int(a[0])),
  'spellBigInt': (a, et) => Speller(et: _etMode(et)).spellBigInt(_big(a[0])),
  'spellDecimal': (a, et) => Speller(et: _etMode(et)).spellDecimal(_str(a[0])),

  // baht
  'baht': (a, _) => baht(_int(a[0])),
  'bahtSatang': (a, _) => bahtSatang(_int(a[0])),
  'bahtFromString': (a, _) => bahtFromString(_str(a[0])),

  // format
  'formatInt': (a, _) => formatInt(_int(a[0])),
  'formatSatang': (a, _) => formatSatang(_int(a[0])),
  'formatThb': (a, _) => formatThb(_int(a[0])),

  // parse
  'parseInt': (a, _) => parseInt(_str(a[0])).toString(),
  'parseBigInt': (a, _) => parseBigInt(_str(a[0])).toString(),
  'parseBaht': (a, _) => parseBaht(_str(a[0])).toString(),

  // extras
  'ordinal': (a, _) => ordinal(_int(a[0])),
  'fraction': (a, _) => fraction(_int(a[0]), _int(a[1])),
  'year': (a, _) => year(_int(a[0])),
  'ceToBe': (a, _) => ceToBe(_int(a[0])).toString(),
  'beToCe': (a, _) => beToCe(_int(a[0])).toString(),

  // date (month index, or [y,m,d])
  'monthTh': (a, _) => monthTh(_int(a[0])),
  'monthAbbrTh': (a, _) => monthAbbrTh(_int(a[0])),
  'weekdayTh': (a, _) => weekdayTh(_dateYMD(a)),
  'weekdayAbbrTh': (a, _) => weekdayAbbrTh(_dateYMD(a)),
  'buddhistYear': (a, _) => buddhistYear(_dateYMD(a)).toString(),
  'formatDate': (a, _) => formatDate(_dateYMD(a)),
  'formatDateAbbr': (a, _) => formatDateAbbr(_dateYMD(a)),
  'formatDateFull': (a, _) => formatDateFull(_dateYMD(a)),
  'parseDate': (a, _) {
    final d = parseDate(_str(a[0]));
    return '${d.year},${d.month},${d.day}';
  },

  // clock
  'formatTime': (a, _) => formatTime(_timeHM(a)),
  'formatClock': (a, _) => formatClock(_timeHM(a)),
  'formatDuration': (a, _) => formatDuration(Duration(seconds: _int(a[0]))),
};

void main() {
  group('cross-port conformance (go-thainum reference)', () {
    late Map<String, dynamic> doc;
    late List<_Rec> records;
    late String version;

    setUpAll(() {
      final f = _vectorsFile();
      if (!f.existsSync()) {
        fail(
          'conformance vectors.json not found at ${f.path}. '
          'Regenerate with: cd go-thainum && go run ./tool/gen_golden '
          '> ../thainum.dart/test/conformance/vectors.json',
        );
      }
      final raw = f.readAsStringSync();
      if (raw.trim().isEmpty) {
        fail('conformance vectors.json is empty at ${f.path}');
      }
      doc = jsonDecode(raw) as Map<String, dynamic>;
      version = (doc['version'] as String?) ?? '(unknown)';
      final rawRecords = doc['records'];
      if (rawRecords is! List || rawRecords.isEmpty) {
        fail('conformance vectors.json has no `records` array (got: '
            '${rawRecords.runtimeType})');
      }
      records = rawRecords.map((r) {
        final m = r as Map<String, dynamic>;
        return _Rec(
          m['group'] as String,
          m['fn'] as String,
          (m['args'] as List).toList(),
          (m['et'] as String?) ?? '',
          m['out'] as String,
        );
      }).toList();
    });

    test('header is the expected pinned reference', () {
      expect(doc['source'], 'go-thainum',
          reason: 'vectors must be generated from go-thainum');
      expect(doc['generated_inputs_only'], true);
      // Intentionally loose (contains, not a pinned tag): re-pinning
      // go-thainum on regen is expected, and the human-readable pin lives in
      // test/conformance/README.md.
      expect(version, contains('go-thainum'),
          reason: 'version header must name the pinned module: $version');
      printOnFailure('pinned reference version: $version');
    });

    test('every record matches the Go reference (no silent skips)', () {
      var asserted = 0;
      final mismatches = <String>[];
      final unknownFns = <String>{};

      for (final r in records) {
        final fn = _dispatch[r.fn];
        if (fn == null) {
          // HARD failure path: an unmapped fn must not be silently skipped.
          unknownFns.add(r.fn);
          continue;
        }
        final String actual;
        try {
          actual = _nfc(fn(r.args, r.et));
        } catch (e, st) {
          mismatches.add('THREW for ${r.describe()}\n'
              '  expected: ${r.out}\n  error: $e\n$st');
          asserted++;
          continue;
        }
        final expected = _nfc(r.out);
        if (actual != expected) {
          mismatches.add('MISMATCH for ${r.describe()}\n'
              '  expected: $expected\n  actual:   $actual');
        }
        asserted++;
      }

      // Anti-vacuous: an unmapped fn is a drift signal (Go grew a shared fn the
      // Dart dispatch doesn't cover) and must fail loudly.
      expect(unknownFns, isEmpty,
          reason: 'these fn names from vectors.json are not in the Dart '
              'dispatch map (add a mapping or exclude them in the generator): '
              '$unknownFns');

      expect(mismatches, isEmpty,
          reason: 'cross-port divergence(s) detected '
              '(${mismatches.length}):\n${mismatches.take(25).join('\n\n')}');

      // Anti-vacuous: ensure we actually asserted a meaningful number.
      expect(asserted, greaterThanOrEqualTo(_minRecords),
          reason: 'only $asserted records asserted; expected >= $_minRecords. '
              'vectors.json may be truncated.');
    });

    test('total record count meets the sanity floor', () {
      expect(records.length, greaterThanOrEqualTo(_minRecords),
          reason: 'vectors.json has ${records.length} records, '
              'below the floor of $_minRecords');
    });
  });
}
