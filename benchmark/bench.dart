/// Baseline benchmark suite for thainum v0.5.0 (Perf-MAX precondition).
///
/// Run:  dart run benchmark/bench.dart
///
/// Pure-Dart VM benchmark. Measures the candidate hot paths called out in
/// issue #1 B8: format* (BigInt round-trip), parse* (tokenizer), spell*, and
/// extractNumbers. Also runs a tokenizer scaling sweep (1x/2x/4x/8x/16x input
/// length) to confirm or deny super-linear growth.
library;

import 'package:thainum/thainum.dart';

import 'harness.dart';

/// Builds a valid stacked-ล้าน Thai word number of roughly [groups] six-digit
/// groups, i.e. a value near 10^(6*groups). Each group's ล้าน-run must strictly
/// decrease, which is exactly what spellBigInt produces, so we just spell a big
/// value back to words — the longest *realistic* valid input.
String longThaiNumber(int sixDigitGroups) {
  // Construct a BigInt with `sixDigitGroups` non-zero groups: value =
  // sum over g of 123456 * 10^(6*g).  spellBigInt then yields the canonical
  // (and longest-per-magnitude) word string.
  var v = BigInt.zero;
  final unit = BigInt.from(123456);
  final million = BigInt.from(1000000);
  var scale = BigInt.one;
  for (var g = 0; g < sixDigitGroups; g++) {
    v += unit * scale;
    scale *= million;
  }
  return spellBigInt(v);
}

void main() {
  print('thainum v0.5.0 baseline benchmark  (Dart VM)');
  print('median of 3 runs; warmup then timed iterations; spread = (max-min)/median');

  // ---- 1. format* (the CSV/PDF export scenario over native ints) ----
  printHeader('format* — small & large native ints (BigInt round-trip)');

  // Small int that nonetheless routes through BigInt.from(n).abs().toString().
  report(bench('formatInt(1234567)', () => consume(formatInt(1234567))));
  report(bench('formatInt(42)', () => consume(formatInt(42))));
  report(bench('formatInt(-9876543210)', () => consume(formatInt(-9876543210))));
  // Max int (19 digits) exercises _groupThousands on a long string.
  report(bench(
      'formatInt(9223372036854775807)', () => consume(formatInt(9223372036854775807))));
  report(bench('formatSatang(212100)', () => consume(formatSatang(212100))));
  report(bench('formatThb(212100)', () => consume(formatThb(212100))));
  report(bench('formatInt(1234567, thaiDigits:true)',
      () => consume(formatInt(1234567, thaiDigits: true))));

  // Baseline for "how cheap could the digit work be?": int.toString() alone,
  // so the BigInt overhead is the delta between this and formatInt.
  report(bench('[ref] (1234567).toString()', () => consume(1234567.toString())));
  report(bench('[ref] (1234567).abs().toString()',
      () => consume(1234567.abs().toString())));
  report(bench('[ref] BigInt.from(1234567).abs().toString()',
      () => consume(BigInt.from(1234567).abs().toString())));

  // ---- 2. parse* (tokenizer) on typical short inputs ----
  printHeader('parse* — typical short Thai word inputs');
  report(bench("parseInt('ยี่สิบเอ็ด')", () => consume(parseInt('ยี่สิบเอ็ด'))));
  report(bench("parseInt('หนึ่งล้านสองแสนสามหมื่น')",
      () => consume(parseInt('หนึ่งล้านสองแสนสามหมื่น'))));
  report(bench("parseInt('๒๑') [digit fast-path]", () => consume(parseInt('๒๑'))));
  report(bench("parseBigInt('หนึ่งล้านล้าน')",
      () => consume(parseBigInt('หนึ่งล้านล้าน'))));

  // ---- 3. spell* on big values ----
  printHeader('spell* — increasing magnitude');
  report(bench('spell(1000000)', () => consume(spell(1000000))));
  report(bench('spell(123456789)', () => consume(spell(123456789))));
  report(bench(
      'spellBigInt(10^12)', () => consume(spellBigInt(BigInt.from(10).pow(12)))));
  report(bench(
      'spellBigInt(10^18)', () => consume(spellBigInt(BigInt.from(10).pow(18)))));
  final big50 = BigInt.parse('9' * 50);
  report(bench('spellBigInt(50-digit 9s)', () => consume(spellBigInt(big50)),
      measure: 50000));

  // ---- 4. extractNumbers on mixed Thai text ----
  printHeader('extractNumbers — mixed free text');
  const mixed =
      'ซื้อมา ๓ ชิ้น ราคาห้าร้อยบาท แล้วก็จ่ายเพิ่มอีกหนึ่งพันสองร้อยห้าสิบบาท '
      'รวมเป็นเงิน 1750 บาท เหลือเงินทอนยี่สิบเอ็ดบาท';
  report(bench('extractNumbers(mixed ~120 chars)',
      () => consume(extractNumbers(mixed)),
      measure: 20000));
  // A longer text = the same paragraph repeated, to see extract scaling.
  final longText = List.filled(10, mixed).join(' และ ');
  report(bench('extractNumbers(mixed x10 ~1.2k chars)',
      () => consume(extractNumbers(longText)),
      measure: 2000));

  // ---- 5. _groupThousands via formatInt on large magnitudes ----
  printHeader('_groupThousands — long digit strings (via formatBigInt-ish)');
  // Use spellBigInt's sibling: format only takes int, so exercise the longest
  // int (19 digits) already done above. For longer digit runs we use a wide
  // BigInt formatted through formatInt's path is not available; show the
  // grouping cost indirectly by formatting max int repeatedly (covered above).
  report(bench('formatInt(max int, 19 digits)',
      () => consume(formatInt(9223372036854775807))));

  // ---- 6. TOKENIZER SCALING SWEEP ----
  printHeader('tokenizer scaling — parseBigInt vs input word-length');
  // Build valid stacked numbers of 1,2,4,8,16,32 six-digit groups.
  for (final groups in [1, 2, 4, 8, 16, 32]) {
    final w = longThaiNumber(groups);
    final r = bench(
      'parseBigInt(${groups}grp len=${w.length})',
      () => consume(parseBigInt(w)),
      warmup: 2000,
      measure: groups <= 8 ? 20000 : 5000,
    );
    report(r);
  }
  print('');
  print('Scaling note: if ns/op roughly quadruples when len doubles it is '
      'O(n^2); if it ~doubles it is linear. See README analysis.');

  // Re-run the sweep printing a compact len->ns table for curve fitting.
  print('');
  print('len(chars)  groups  ns/op  ns/char');
  for (final groups in [1, 2, 4, 8, 16, 32, 64]) {
    final w = longThaiNumber(groups);
    final r = bench(
      'sweep',
      () => consume(parseBigInt(w)),
      warmup: 1000,
      measure: groups <= 8 ? 10000 : 3000,
    );
    print('${w.length.toString().padLeft(9)}  '
        '${groups.toString().padLeft(6)}  '
        '${r.nsPerOp.toStringAsFixed(0).padLeft(8)}  '
        '${(r.nsPerOp / w.length).toStringAsFixed(2).padLeft(7)}');
  }

  // Keep the optimizer honest.
  if (blackhole == 0x12345) print('unreachable $blackhole');
}
