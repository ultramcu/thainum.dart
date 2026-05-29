// Property tests: spelling a number and parsing the words back yields the
// original value. The corpus is a SEEDED Random plus an explicit list of
// boundary values, so failures are deterministic and reproducible. The
// integer property is exercised under BOTH EtMode values (the parser accepts
// either เอ็ด or หนึ่ง form), guarding the speller↔parser contract on both
// conventions.

import 'dart:math';

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

// Fixed seed so CI is deterministic. Change it (and note it) to re-roll.
const int kSeedValue = 20260529;

void main() {
  group('parseInt(spell(n)) == n', () {
    final rng = Random(kSeedValue);

    final boundaries = <int>[
      0, 1, 5, 10, 11, 20, 21, 100, 101, 1000, 1001,
      1000000, 1000001, // 10^6, 10^6 + 1
      1000000000000, // 10^12
      1000000000000000000, // 10^18
      -1, -5, -21, -101, -1000000,
    ];

    for (final et in EtMode.values) {
      final speller = Speller(et: et);

      test('boundaries ($et)', () {
        for (final n in boundaries) {
          final words = speller.spellInt(n);
          expect(
            parseInt(words),
            n,
            reason: '$et n=$n words="$words"',
          );
        }
      });

      test('seeded corpus ($et, seed=$kSeedValue)', () {
        for (var i = 0; i < 2000; i++) {
          // Mix small and large magnitudes; include negatives.
          final mag = rng.nextInt(1 << 31);
          final n = rng.nextBool() ? -mag : mag;
          final words = speller.spellInt(n);
          expect(
            parseInt(words),
            n,
            reason: '$et seed=$kSeedValue i=$i n=$n words="$words"',
          );
        }
      });

      // VM-only: the most-negative int (-2^63) is not representable on the
      // web/JS 53-bit int target, so this literal lives in a VM-only test. It
      // locks the `BigInt.from(n).abs()` magnitude safeguard in spellInt that
      // avoids `(-n).abs()` overflow when negating the most-negative int.
      test('int-min boundary ($et) [VM-only]', () {
        const n = -9223372036854775808; // -2^63 == (-1 << 63)
        final words = speller.spellInt(n);
        expect(
          parseInt(words),
          n,
          reason: '$et n=$n words="$words"',
        );
      });
    }

    // VM-only: also exercise the top-level spell() (default EtMode) on -2^63.
    test('int-min boundary (top-level spell) [VM-only]', () {
      const n = -9223372036854775808; // -2^63 == (-1 << 63)
      final words = spell(n);
      expect(parseInt(words), n, reason: 'n=$n words="$words"');
    });
  });

  group('parseBigInt(spellBigInt(n)) == n', () {
    final rng = Random(kSeedValue + 1);

    final boundaries = <BigInt>[
      BigInt.zero,
      BigInt.one,
      BigInt.from(10).pow(6),
      BigInt.from(10).pow(6) + BigInt.one,
      BigInt.from(10).pow(12),
      BigInt.from(10).pow(18),
      BigInt.parse('123456789012345678901234567890'),
      -BigInt.parse('987654321098765432109876543210'),
      -BigInt.one,
    ];

    test('boundaries', () {
      for (final n in boundaries) {
        final words = spellBigInt(n);
        expect(parseBigInt(words), n, reason: 'n=$n words="$words"');
      }
    });

    // The boundaries table above spells under the default `always` form. This
    // confirms the parser also accepts the EtMode.tensOnly (หนึ่ง) output for
    // cross-`ล้าน`-group trailing-1 values, where the units 1 sits above a zero
    // tens across group boundaries (10^6+1, 10^12+1, 10^18+1, …).
    test('tensOnly cross-group boundaries', () {
      final speller = Speller(et: EtMode.tensOnly);
      final tensOnlyBoundaries = <BigInt>[
        BigInt.one,
        BigInt.from(10).pow(6) + BigInt.one, // 10^6 + 1
        BigInt.from(10).pow(12) + BigInt.one, // 10^12 + 1
        BigInt.from(10).pow(18) + BigInt.one, // 10^18 + 1
        BigInt.from(10).pow(24) + BigInt.one, // 10^24 + 1
        BigInt.parse('1000001000001000001'), // trailing 1 in several groups
        -(BigInt.from(10).pow(12) + BigInt.one), // negative cross-group
      ];
      for (final n in tensOnlyBoundaries) {
        final words = speller.spellBigInt(n);
        expect(parseBigInt(words), n, reason: 'tensOnly n=$n words="$words"');
      }
    });

    test('seeded large corpus (seed=${kSeedValue + 1})', () {
      for (var i = 0; i < 500; i++) {
        // Build a random big magnitude up to ~24 digits.
        final digits = 1 + rng.nextInt(24);
        final b = StringBuffer();
        b.write(1 + rng.nextInt(9)); // no leading zero
        for (var d = 1; d < digits; d++) {
          b.write(rng.nextInt(10));
        }
        var n = BigInt.parse(b.toString());
        if (rng.nextBool()) n = -n;
        final words = spellBigInt(n);
        expect(
          parseBigInt(words),
          n,
          reason: 'seed=${kSeedValue + 1} i=$i n=$n words="$words"',
        );
      }
    });
  });

  group('parseBaht(bahtSatang(s)) == s', () {
    final rng = Random(kSeedValue + 2);

    final boundaries = <int>[0, 25, 2121, 100000, -25, -2121, -100000];

    test('boundaries', () {
      for (final s in boundaries) {
        final text = bahtSatang(s);
        expect(parseBaht(text), s, reason: 's=$s text="$text"');
      }
    });

    test('seeded corpus (seed=${kSeedValue + 2})', () {
      for (var i = 0; i < 1000; i++) {
        final mag = rng.nextInt(1 << 30);
        final s = rng.nextBool() ? -mag : mag;
        final text = bahtSatang(s);
        expect(
          parseBaht(text),
          s,
          reason: 'seed=${kSeedValue + 2} i=$i s=$s text="$text"',
        );
      }
    });
  });
}
