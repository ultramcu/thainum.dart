/// Focused scaling analysis for the tokenizer and extractNumbers.
///
/// Run:  dart run benchmark/scaling.dart
///
/// Fits a power law ns = a * len^k by regressing log(ns) on log(len) and
/// reports the exponent k for parseBigInt (the tokenizer) and extractNumbers.
library;

import 'dart:math' as math;

import 'package:thainum/thainum.dart';

import 'bench.dart' show longThaiNumber;
import 'harness.dart';

double exponentFit(List<double> lens, List<double> times) {
  // least-squares slope of log(time) vs log(len)
  final n = lens.length;
  var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
  for (var i = 0; i < n; i++) {
    final x = math.log(lens[i]);
    final y = math.log(times[i]);
    sx += x;
    sy += y;
    sxx += x * x;
    sxy += x * y;
  }
  return (n * sxy - sx * sy) / (n * sxx - sx * sx);
}

void main() {
  print('=== Tokenizer power-law fit (parseBigInt over stacked ล้าน) ===');
  print('len(chars)   ns/op    ns/char');
  final lens = <double>[];
  final times = <double>[];
  for (final groups in [1, 2, 4, 8, 16, 32, 64, 128]) {
    final w = longThaiNumber(groups);
    final r = bench('t', () => consume(parseBigInt(w)),
        warmup: 1000, measure: groups <= 8 ? 8000 : (groups <= 32 ? 2000 : 500));
    lens.add(w.length.toDouble());
    times.add(r.nsPerOp);
    print('${w.length.toString().padLeft(10)}  '
        '${r.nsPerOp.toStringAsFixed(0).padLeft(8)}  '
        '${(r.nsPerOp / w.length).toStringAsFixed(2).padLeft(8)}');
  }
  print('Overall power-law exponent k (all points): '
      '${exponentFit(lens, times).toStringAsFixed(3)}');
  // Exponent restricted to the "realistic" regime (<= ~400 chars).
  final realLens = lens.sublist(0, 4);
  final realTimes = times.sublist(0, 4);
  print('Exponent k for len<=408 (realistic): '
      '${exponentFit(realLens, realTimes).toStringAsFixed(3)}');
  final tailLens = lens.sublist(4);
  final tailTimes = times.sublist(4);
  print('Exponent k for len>=1072 (pathological tail): '
      '${exponentFit(tailLens, tailTimes).toStringAsFixed(3)}');

  print('');
  print('=== extractNumbers power-law fit (word run repeated) ===');
  const unit = 'หนึ่งพันสองร้อยสามสิบสี่ ';
  print('len(chars)   ns/op    ns/char');
  final elens = <double>[];
  final etimes = <double>[];
  for (final reps in [1, 2, 4, 8, 16, 32]) {
    final t = unit * reps;
    final r = bench('e', () => consume(extractNumbers(t)),
        warmup: 200, measure: reps <= 8 ? 2000 : 500);
    elens.add(t.length.toDouble());
    etimes.add(r.nsPerOp);
    print('${t.length.toString().padLeft(10)}  '
        '${r.nsPerOp.toStringAsFixed(0).padLeft(8)}  '
        '${(r.nsPerOp / t.length).toStringAsFixed(2).padLeft(8)}');
  }
  print('extractNumbers power-law exponent k: '
      '${exponentFit(elens, etimes).toStringAsFixed(3)}');

  if (blackhole == 0x999) print('x');
}
