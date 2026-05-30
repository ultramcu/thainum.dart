/// Hand-rolled micro-benchmark harness (no external dependency).
///
/// For each registered benchmark it:
///   1. runs [warmup] untimed iterations (lets the VM JIT/optimize),
///   2. runs [measure] timed iterations, three separate times (runs),
///   3. reports the MEDIAN ns/op and ops/sec plus the 3-run spread.
///
/// A `blackhole` sink defeats dead-code elimination so the work is not
/// optimized away.
library;

int blackhole = 0;

/// Consumes a value so the optimizer cannot drop the benchmarked call.
void consume(Object? v) {
  // Mix something cheap and value-dependent into a global.
  blackhole = (blackhole ^ v.hashCode) & 0x7fffffff;
}

class BenchResult {
  BenchResult(this.name, this.nsPerOp, this.runsNs, this.iters);
  final String name;
  final double nsPerOp; // median ns/op
  final List<double> runsNs; // ns/op for each of the 3 runs
  final int iters;

  double get opsPerSec => 1e9 / nsPerOp;
  double get minNs => runsNs.reduce((a, b) => a < b ? a : b);
  double get maxNs => runsNs.reduce((a, b) => a > b ? a : b);
  double get spreadPct => (maxNs - minNs) / nsPerOp * 100;
}

double _median(List<double> xs) {
  final s = List<double>.of(xs)..sort();
  final n = s.length;
  if (n.isOdd) return s[n ~/ 2];
  return (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// Times [body] which must perform exactly one unit of work per call.
BenchResult bench(
  String name,
  void Function() body, {
  int warmup = 20000,
  int measure = 200000,
  int runs = 3,
}) {
  for (var i = 0; i < warmup; i++) {
    body();
  }
  final runNs = <double>[];
  for (var r = 0; r < runs; r++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < measure; i++) {
      body();
    }
    sw.stop();
    runNs.add(sw.elapsedTicks * (1e9 / sw.frequency) / measure);
  }
  return BenchResult(name, _median(runNs), runNs, measure);
}

void printHeader(String title) {
  print('');
  print('=== $title ===');
  print('${'name'.padRight(42)}  ${'ns/op'.padLeft(12)}  '
      '${'ops/sec'.padLeft(14)}  ${'spread'.padLeft(8)}  iters');
}

void report(BenchResult r) {
  final ops = r.opsPerSec;
  final opsStr = ops >= 1e6
      ? '${(ops / 1e6).toStringAsFixed(2)}M'
      : ops >= 1e3
          ? '${(ops / 1e3).toStringAsFixed(1)}K'
          : ops.toStringAsFixed(0);
  print('${r.name.padRight(42)}  '
      '${r.nsPerOp.toStringAsFixed(1).padLeft(12)}  '
      '${opsStr.padLeft(14)}  '
      '${'${r.spreadPct.toStringAsFixed(1)}%'.padLeft(8)}  '
      '${r.iters}');
}
