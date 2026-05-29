# Cross-port conformance vectors

`vectors.json` is a language-neutral golden file generated from the **Go**
reference implementation, [`go-thainum`](https://github.com/ultramcu/go-thainum)
(the source of truth). The Dart test `test/conformance_test.dart` replays every
record and asserts that `thainum.dart` produces byte-for-byte identical output
on the **shared surface**, so the two same-owner libraries cannot silently
drift.

The vectors are checked in, so Dart CI runs this test **without needing Go**.

## Pinned reference

The header of `vectors.json` records the exact go-thainum version it was
generated from, e.g.:

```json
"version": "github.com/ultramcu/go-thainum@v0.3.2-1-gfb80de7"
```

(`git describe --tags --always --dirty` of the go-thainum checkout at generation
time.)

## Regenerating

From a checkout of go-thainum that sits next to this repo:

```sh
cd go-thainum && go run ./tool/gen_golden > ../thainum.dart/test/conformance/vectors.json
```

The generator lives at `go-thainum/tool/gen_golden/main.go`. Its input set is
**fixed and deterministic** — no `time.Now`, no host locale, no host timezone;
all dates/times are built in UTC from explicit components, and output ordering
is stable (no map iteration). UTF-8 is emitted NFC and un-escaped (literal Thai).

## What is covered (the shared surface)

`numerals` (toThaiDigits / toArabicDigits), `spell` (int / bigint / decimal,
**both EtMode values**), `baht` (baht / bahtSatang / bahtFromString), `format`
(formatInt / formatSatang / formatThb), `parse` (parseInt / parseBigInt /
parseBaht), `extras` (ordinal / fraction / year / ceToBe / beToCe), `date`
(monthTh / monthAbbrTh / weekdayTh / weekdayAbbrTh / buddhistYear / formatDate /
formatDateAbbr / formatDateFull / parseDate), `clock` (formatTime / formatClock
/ formatDuration).

## What is intentionally excluded

Surface that exists on only one side (so there is nothing to compare):

- **Dart-only:** `tryParseInt/tryParseBigInt/tryParseBaht/tryParseDate`, the
  `thaiDigits:` flag on the formatters, the `allowColloquial`/`lenient` parse
  options, `percent`, `short`/`spellShort`/`formatShort`, `speak`/`speakDigits`,
  `extractNumbers`, `parseDecimal`, the `thai_id` helpers, and the typed
  `Baht`/`Satang` value wrappers / extension methods.
- **Go-only:** `BahtFromFloat` / `SatangFromFloat` (lossy float entry points;
  the Dart `bahtFromDouble`/`satangFromFloat` exist but float rounding is not a
  cross-port guarantee we assert).

The Dart conformance test fails loudly if `vectors.json` is missing/empty, has
no records, contains an `fn` not present in the Dart dispatch map, or asserts
fewer than 150 records — so coverage cannot silently shrink.
