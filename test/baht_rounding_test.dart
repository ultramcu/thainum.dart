// Tests for the selectable baht rounding mode (B5).
//
// `bahtFromString` rounds a decimal baht string to two fractional places
// (satang) using a [SatangRounding] mode. The default must reproduce the
// historical half-away-from-zero behaviour byte-identically. None of the modes
// may touch a `double` — the rounding is decided entirely from the digit
// string.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  // The set of decimal strings every pre-B5 baht test (and the doc comments)
  // exercised, plus a spread of >2-digit fractions. The default mode MUST
  // reproduce the historical output for all of these.
  const regressionInputs = <String>[
    '0',
    '0.00',
    '21.21',
    '100',
    '100.00',
    '1000.50',
    '0.5',
    '0.05',
    '0.005',
    '0.004',
    '0.006',
    '0.015',
    '0.025',
    '12.345',
    '12.344',
    '-21.21',
    '-0.005',
    '-0.004',
    '1234567.89',
    '0.999',
    '99.995',
  ];

  // The historical algorithm, copied verbatim, as an independent oracle so the
  // regression guard does not just compare the implementation to itself.
  String historicalBahtFromString(String amount) {
    var s = amount.trim();
    var neg = false;
    if (s.startsWith('-')) {
      neg = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    final dot = s.indexOf('.');
    final intPart = dot >= 0 ? s.substring(0, dot) : s;
    final frac = dot >= 0 ? s.substring(dot + 1) : '';
    var sat = BigInt.parse(intPart.isEmpty ? '0' : intPart) * BigInt.from(100);
    var cents = 0;
    if (frac.isNotEmpty) cents += (frac.codeUnitAt(0) - 0x30) * 10;
    if (frac.length >= 2) cents += frac.codeUnitAt(1) - 0x30;
    if (frac.length >= 3 && frac.codeUnitAt(2) >= 0x35) cents++;
    sat += BigInt.from(cents);
    // mirror bahtFromString's "ลบ only when non-zero" rule
    final out = bahtSatangBigInt(sat);
    if (neg && sat.sign != 0) return 'ลบ$out';
    return out;
  }

  group('default rounding is byte-identical to historical behaviour', () {
    for (final input in regressionInputs) {
      test('"$input"', () {
        expect(bahtFromString(input), historicalBahtFromString(input));
        // explicit-default == implicit-default
        expect(
          bahtFromString(input, rounding: SatangRounding.halfAwayFromZero),
          bahtFromString(input),
        );
      });
    }
  });

  // A helper that exposes the satang result of each mode via the public API.
  // `bahtSatang(s)` is injective enough for our boundary checks, but to be
  // unambiguous we compare the produced text to bahtSatang(expectedSatang).
  String expectedText(int satang) => bahtSatang(satang);

  group('halfAwayFromZero', () {
    const m = SatangRounding.halfAwayFromZero;
    test('0.005 -> 1 satang', () {
      expect(bahtFromString('0.005', rounding: m), expectedText(1));
    });
    test('0.004 -> 0 satang', () {
      expect(bahtFromString('0.004', rounding: m), expectedText(0));
    });
    test('0.015 -> 2 satang', () {
      expect(bahtFromString('0.015', rounding: m), expectedText(2));
    });
    test('0.0051 -> 1 satang (above half)', () {
      expect(bahtFromString('0.0051', rounding: m), expectedText(1));
    });
    test('-0.005 -> -1 satang magnitude', () {
      expect(bahtFromString('-0.005', rounding: m), 'ลบ${expectedText(1)}');
    });
  });

  group('halfEven (banker\'s rounding)', () {
    const m = SatangRounding.halfEven;
    test('0.005 -> 0 satang (round to even)', () {
      expect(bahtFromString('0.005', rounding: m), expectedText(0));
    });
    test('0.015 -> 2 satang (round to even)', () {
      expect(bahtFromString('0.015', rounding: m), expectedText(2));
    });
    test('0.025 -> 2 satang (round to even)', () {
      expect(bahtFromString('0.025', rounding: m), expectedText(2));
    });
    test('0.0151 -> 2 satang (above half, normal round up)', () {
      expect(bahtFromString('0.0151', rounding: m), expectedText(2));
    });
    test('0.0049 -> 0 satang (below half)', () {
      expect(bahtFromString('0.0049', rounding: m), expectedText(0));
    });
    test('-0.025 -> -2 satang magnitude (even)', () {
      expect(bahtFromString('-0.025', rounding: m), 'ลบ${expectedText(2)}');
    });
  });

  group('truncate (toward zero)', () {
    const m = SatangRounding.truncate;
    test('0.009 -> 0 satang', () {
      expect(bahtFromString('0.009', rounding: m), expectedText(0));
    });
    test('0.019 -> 1 satang', () {
      expect(bahtFromString('0.019', rounding: m), expectedText(1));
    });
    test('-0.009 -> 0 satang', () {
      expect(bahtFromString('-0.009', rounding: m), expectedText(0));
    });
    test('-0.019 -> -1 satang magnitude', () {
      expect(bahtFromString('-0.019', rounding: m), 'ลบ${expectedText(1)}');
    });
  });

  group('ceil (toward +inf)', () {
    const m = SatangRounding.ceil;
    test('0.001 -> 1 satang', () {
      expect(bahtFromString('0.001', rounding: m), expectedText(1));
    });
    test('0.010 -> 1 satang (no tail, no bump)', () {
      expect(bahtFromString('0.010', rounding: m), expectedText(1));
    });
    test('-0.009 -> 0 satang (magnitude truncates)', () {
      expect(bahtFromString('-0.009', rounding: m), expectedText(0));
    });
    test('-0.019 -> -1 satang magnitude', () {
      expect(bahtFromString('-0.019', rounding: m), 'ลบ${expectedText(1)}');
    });
  });

  group('floor (toward -inf)', () {
    const m = SatangRounding.floor;
    test('0.009 -> 0 satang', () {
      expect(bahtFromString('0.009', rounding: m), expectedText(0));
    });
    test('0.019 -> 1 satang', () {
      expect(bahtFromString('0.019', rounding: m), expectedText(1));
    });
    test('-0.001 -> -1 satang magnitude', () {
      expect(bahtFromString('-0.001', rounding: m), 'ลบ${expectedText(1)}');
    });
    test('-0.010 -> -1 satang magnitude (no tail)', () {
      expect(bahtFromString('-0.010', rounding: m), 'ลบ${expectedText(1)}');
    });
  });

  group('exactly-on-satang and zero-tail inputs are mode-invariant', () {
    const inputs = ['12.34', '0.50', '100.00', '-7.07', '0.5', '0.05'];
    for (final mode in SatangRounding.values) {
      test('$mode leaves exact two-decimal inputs unchanged', () {
        for (final s in inputs) {
          expect(
            bahtFromString(s, rounding: mode),
            bahtFromString(s, rounding: SatangRounding.truncate),
            reason: '"$s" under $mode',
          );
        }
      });
    }
  });

  test('no float path: many-digit fraction does not lose precision', () {
    // A fraction far longer than any double can represent. The tail past the
    // second digit must still drive a correct half-even decision.
    expect(
      bahtFromString('0.00500000000000000000000000001',
          rounding: SatangRounding.halfEven),
      expectedText(1), // strictly above half -> round up despite even
    );
    expect(
      bahtFromString('0.005000000000000000000000000000',
          rounding: SatangRounding.halfEven),
      expectedText(0), // exactly half -> round to even (0)
    );
  });

  test('SatangRounding has the five documented modes', () {
    expect(SatangRounding.values, hasLength(5));
    expect(
      SatangRounding.values.toSet(),
      {
        SatangRounding.halfAwayFromZero,
        SatangRounding.halfEven,
        SatangRounding.truncate,
        SatangRounding.ceil,
        SatangRounding.floor,
      },
    );
  });
}
