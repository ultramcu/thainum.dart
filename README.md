# thainum

[![pub package](https://img.shields.io/pub/v/thainum.svg)](https://pub.dev/packages/thainum)
[![CI](https://github.com/ultramcu/thainum.dart/actions/workflows/ci.yml/badge.svg)](https://github.com/ultramcu/thainum.dart/actions/workflows/ci.yml)

**ชุดเครื่องมือจัดการตัวเลขภาษาไทยแบบครบวงจรสำหรับภาษา Dart — เลขไทย, อ่านเป็นคำ, บาทตัวอักษร, จัดรูปแบบ และแปลงคำกลับเป็นตัวเลข**

**A comprehensive Thai number toolkit for Dart — Thai numerals, number-to-words, baht text, formatting, Thai dates/times, and (uniquely) reverse parsing of Thai words back into numbers.**

Pure Dart, MIT-licensed, **no Flutter and no `intl` dependency** (the Thai
tables are bundled). A faithful port of
[`go-thainum`](https://github.com/ultramcu/go-thainum).

```sh
dart pub add thainum
```

## Reverse parsing — words back into numbers (the flagship)

Essentially nothing else turns Thai *words* back into numbers. `thainum` does:

```dart
import 'package:thainum/thainum.dart';

parseInt('ยี่สิบเอ็ด');                       // 21
parseInt('หนึ่งร้อยเอ็ด');                     // 101  (เอ็ด form)
parseInt('หนึ่งร้อยหนึ่ง');                    // 101  (หนึ่ง form — both accepted)
parseInt('๒๑');                               // 21   (Thai digits)
parseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์');   // 2121 (satang)
parseBigInt('หนึ่งล้านล้านล้าน');             // 10^18

// Stacked ล้าน is handled correctly:
parseBigInt('หนึ่งล้านล้าน');                 // 10^12
```

All parse failures throw `ThaiNumException`, which implements `FormatException`:

```dart
try {
  parseInt('สิบสิบ'); // ascending/repeat place is invalid
} on FormatException catch (e) {
  print(e); // ThaiNumException: thainum: misplaced place word ("สิบ")
}
```

### Non-throwing parsing — `tryParse*` (v0.3.0+)

When you would rather branch on a `null` than catch a `FormatException`, every
parser has a `tryParse*` sibling (and matching `String` extension):

```dart
tryParseInt('ยี่สิบเอ็ด');  // 21
tryParseInt('สิบสิบ');      // null   (invalid → no throw)
tryParseBigInt('หนึ่งล้านล้าน'); // 10^12
tryParseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'); // 2121
tryParseDate('5 มิถุนายน 2567'); // DateTime.utc(2024, 6, 5)

'สิบสิบ'.tryParseThaiInt(); // null
```

## Read digits one by one — `speakDigits` (อ่านเรียงตัว, v0.3.0+)

Phone numbers, account numbers and PINs are read digit-by-digit, not as a
quantity:

```dart
speakDigits('2566');         // 'สอง ห้า หก หก'
speakDigits('081-234-5678'); // 'ศูนย์ แปด หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด'
'0812345678'.speakThaiDigits(); // same as above

// Thai numerals accepted; punctuation collapses to one separator.
speakDigits('๒๕๖๖');                          // 'สอง ห้า หก หก'
speakDigits('2566', colloquialTwo: true);     // 'โท ห้า หก หก'  (2 → โท)
speakDigits('2566', separator: '-');          // 'สอง-ห้า-หก-หก'
```

## Thai numeral output — the `thaiDigits:` flag (v0.3.0+)

The formatters and date helpers take an optional `thaiDigits:` flag. When true
only the digits become Thai numerals — commas, the decimal point, the `฿`
symbol, the `-` sign and labels like `พ.ศ.` stay ASCII:

```dart
formatInt(1234567, thaiDigits: true); // '๑,๒๓๔,๕๖๗'
formatThb(2121, thaiDigits: true);    // '฿๒๑.๒๑'
formatDateFull(d, thaiDigits: true);  // 'วันพุธที่ ๕ มิถุนายน พ.ศ. ๒๕๖๗'

1234567.toThousandsString(thaiDigits: true);  // '๑,๒๓๔,๕๖๗'
const Satang(2121).toThb(thaiDigits: true);   // '฿๒๑.๒๑'
d.toThaiDate(thaiDigits: true);               // '๕ มิถุนายน ๒๕๖๗'
```

The default (`thaiDigits: false`) output is byte-identical to previous releases.

## Find numbers in free text — `extractNumbers` (v0.4.0+)

Scan any text for embedded Thai numbers (words and/or digit characters). Each
`NumberMatch` carries the `value`, the matched substring, its `start`/`end`
offsets into the original text (so `text.substring(start, end) == matched`),
and whether it came from words (`isWord`) or digits (`isDigits`).

```dart
for (final m in extractNumbers('ซื้อมา ๓ ชิ้น ราคาห้าร้อยบาท')) {
  print('${m.matched} = ${m.value}');
}
// ๓ = 3        (isDigits)
// ห้าร้อย = 500 (isWord)
```

At each position it consumes the **maximal valid number** — a run of digits, or
the longest contiguous run of number-words the grammar accepts. So `'ยี่สิบเอ็ด'`
is one match (21), and `'ห้าร้อยสิบสิบ'` yields `'ห้าร้อยสิบ'` (510) then
`'สิบ'` (10).

## Parse decimals — `parseDecimal` (v0.4.0+)

The inverse of `spellDecimal`: integer part parsed normally, fractional part read
digit-by-digit. Returns a canonical decimal string.

```dart
parseDecimal('สิบสองจุดสามสี่'); // '12.34'
parseDecimal('ศูนย์จุดห้า');      // '0.5'
'สิบสองจุดสามสี่'.parseThaiDecimal(); // '12.34'
```

### Lenient / colloquial inputs (opt-in, v0.4.0+)

`parseInt`, `parseBigInt`, `parseBaht` and `parseDecimal` take two opt-in flags
(both default `false`, so the strict path is unchanged):

```dart
parseInt('ร้อยนึง', allowColloquial: true); // 101  (accept นึง as 1)
parseInt('ยี่สิบ เอ็ด', lenient: true);      // 21   (strip spaces/NBSP/zero-width)
```

## Thai National / Tax ID (v0.4.0+)

Validate (MOD-11), format, parse, classify and read a 13-digit Thai National ID
(the personal Tax ID is the same number).

```dart
isValidThaiId('1-1017-00230-70-8'); // true (dashes/spaces/Thai numerals ok)
formatThaiId('1101700230708');      // '1-1017-00230-70-8'
parseThaiId('1-1017-00230-70-8');   // '1101700230708'
classifyThaiId('1101700230708');    // ThaiIdKind.thaiBornRegisteredOnTime
speakThaiId('1101700230708');       // 'หนึ่ง หนึ่ง ศูนย์ …' (digit-by-digit)

'1101700230708'.isValidThaiId();    // true (String extension)
```

`classifyThaiId` maps the leading digit to a DOPA category and returns
`ThaiIdKind.unknown` (rather than guessing) for leading digit 0/9 or any
non-13-digit input.

## Percent (v0.4.0+)

```dart
percent(25);                                          // 'ร้อยละยี่สิบห้า'
percent(25.5);                                        // 'ร้อยละยี่สิบห้าจุดห้า'
percent(25, style: PercentStyle.colloquialPercent);   // 'ยี่สิบห้าเปอร์เซ็นต์'
formatPercent(25.5);                                  // '25.5%'
25.toThaiPercent();                                   // 'ร้อยละยี่สิบห้า'
```

## Lottery reading helpers (v0.5.0+)

Reading + draw-date only — no prize checking and no data. Numbers are read
digit-by-digit (อ่านเรียงตัว), the way lottery numbers are read aloud.

```dart
speakLotteryNumber('123456');           // 'หนึ่ง สอง สาม สี่ ห้า หก'
speakTwoDigit('07');                    // 'ศูนย์ เจ็ด'   (เลขท้าย 2 ตัว)
speakThreeDigit('507');                 // 'ห้า ศูนย์ เจ็ด' (เลขท้าย 3 ตัว)
speakLotteryNumber('222', colloquialTwo: true); // throws (must be 6 digits)

isLotteryDrawDate(DateTime(2024, 6, 16)); // true  (draws are the 1st & 16th)
lotteryDrawDates(2024, 6);                // [2024-06-01, 2024-06-16]
```

Arabic or Thai numerals are accepted; a wrong length or a non-digit throws
`ThaiNumException`. The draw-date helpers cover the *regular* schedule, not the
rare official holiday shifts.

## Thai phone numbers (v0.5.0+)

```dart
formatThaiPhone('0812345678');   // '081-234-5678'  (mobile 3-3-4)
formatThaiPhone('021234567');    // '02-123-4567'   (landline, best-effort)
thaiPhoneKind('0812345678');     // ThaiPhoneKind.mobile
thaiPhoneKind('1800123456');     // ThaiPhoneKind.tollFree
thaiPhoneKind('1669');           // ThaiPhoneKind.shortCode
normalizeThaiPhone('0812345678');// '+66812345678'  (E.164)
speakThaiPhone('0812345678');    // 'ศูนย์ แปด หนึ่ง สอง …' (digit-by-digit)
speakThaiPhone('0812345678', colloquialTwo: true); // '… โท …'

'0812345678'.formatThaiPhone();  // String extensions, too
```

Separators, spaces, Thai numerals and a leading `+66` are accepted. Mobile
`3-3-4` grouping is confident; landline area-code grouping is **best-effort**
(Thai area codes are variable-length), and `thaiPhoneKind` returns
`ThaiPhoneKind.unknown` whenever a number doesn't clearly match a known pattern.

## Command-line tool (v0.5.0+)

```sh
dart pub global activate thainum     # then: thainum <cmd> ...
# or, without activating:
dart run thainum:thainum <cmd> ...

thainum spell 101                  # หนึ่งร้อยเอ็ด
thainum spell 101 --et=tensOnly    # หนึ่งร้อยหนึ่ง
thainum baht 21.21                 # ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์
thainum parse ยี่สิบเอ็ด           # 21
thainum digits 2566                # ๒๕๖๖
thainum date 2024-06-05 --full     # วันพุธที่ 5 มิถุนายน พ.ศ. 2567
thainum spell 101 --json           # {"words": "หนึ่งร้อยเอ็ด"}
```

Subcommands: `spell`, `baht`, `parse`, `digits`, `date`. Flags: `--et`,
`--full`/`--abbr` (for `date`), `--json`, `--help`. The CLI's argument parser is
hand-rolled, so the package stays **dependency-free** (no `package:args`).

## Receiver-style API (v0.2.0+)

Every top-level function below is also available as an extension method on
its receiver type, so the same calls read naturally in a chain. The
extensions are exported by the same `import 'package:thainum/thainum.dart';`
— no extra import needed.

```dart
21.toThaiWords();                      // 'ยี่สิบเอ็ด'
'101'.toThaiDigits();                  // '๑๐๑'
1234567.toThousandsString();           // '1,234,567'
'ยี่สิบเอ็ด'.parseThaiInt();           // 21

const Baht(100).toBahtText();          // 'หนึ่งร้อยบาทถ้วน'
const Satang(2121).toBahtText();       // 'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'
const Satang(2121).toThb();            // '฿21.21'

final d = DateTime.utc(2024, 6, 5);
d.toThaiDateFull();                    // 'วันพุธที่ 5 มิถุนายน พ.ศ. 2567'
d.buddhistYear;                        // 2567   (getter — property)
```

The `Baht` / `Satang` / `BahtBigInt` / `SatangBigInt` wrappers make the
money unit a compile-time guarantee: a satang amount can never be passed
where baht is expected. `int.toBahtText()` (and the `BigInt` / `double`
versions) interpret the receiver as whole baht — the unambiguous default.

The function API (`spell(21)`, `baht(100)`, `parseInt(...)`) keeps working
unchanged.

## Features

- **Thai numerals** — `toThaiDigits` / `toArabicDigits` (`101` ⇄ `๑๐๑`).
- **Spell numbers as Thai words** — `int`, `BigInt`, and decimals, correct to
  ล้านล้าน (10¹²) **and beyond**.
- **Abbreviated reading** — `spellShort` / `formatShort` render large values
  with a single "สากล พัน/ล้าน" scale unit (`1.5 ล้าน`, `2.3 พันล้าน`).
- **Baht text (บาทตัวอักษร)** — render currency amounts as the formal Thai
  spelling used on cheques and invoices.
- **Formatting** — thousands separators, satang-to-decimal, and a `฿` display.
- **Reverse parsing** — turn Thai words *back* into numbers and satang.
- **Ordinals, fractions & Buddhist-Era years** — `ordinal` (ที่…),
  `fraction` (เศษ…ส่วน…), `year` (พุทธศักราช…), plus `ceToBe` / `beToCe`.
- **Thai dates** — Thai month/weekday names, Buddhist-Era year, three formatters,
  and `parseDate` to turn a Thai date string *back* into a `DateTime`.
- **Thai time & durations** — `formatTime` (formal นาฬิกา), `formatClock`
  (colloquial ตี / โมง / ทุ่ม), and `formatDuration`.
- **Money is exact** — amounts are handled in integer **satang** (1 baht = 100
  satang) or `BigInt`, **never `double`**. A clearly-labelled lossy float entry
  point exists for convenience.
- **EtMode** — choose between the Royal-Institute-recommended `เอ็ด` form and the
  plain `หนึ่ง` form for trailing ones.

## Quick start

### Thai numerals

```dart
toThaiDigits('101');   // ๑๐๑
toArabicDigits('๑๐๑'); // 101
```

### Spell numbers as Thai words

```dart
spell(21);  // ยี่สิบเอ็ด
spell(101); // หนึ่งร้อยเอ็ด
spellBigInt(BigInt.parse('1000000000000')); // หนึ่งล้านล้าน
spellDecimal('12.34'); // สิบสองจุดสามสี่
```

### Abbreviated large numbers (สากล พัน/ล้าน)

For values `>= 1,000,000`, abbreviate to the largest scale unit. The scale
units sit a factor of **1000** apart, starting at `10⁶` (ล้าน): `10⁹` is
พันล้าน, `10¹²` is ล้านล้าน, `10¹⁵` is พันล้านล้าน, and so on — so
`50,000,000,000` reads **ห้าสิบพันล้าน**, not "ห้าหมื่นล้าน".

```dart
formatShort(1500000);      // 1.5 ล้าน
formatShort(2300000000);   // 2.3 พันล้าน
formatShort(50000000000);  // 50 พันล้าน
spellShort(1500000);       // หนึ่งจุดห้าล้าน
spellShort(1200000000000); // หนึ่งจุดสองล้านล้าน
```

The coefficient is computed exactly from the digit string (no `double`),
rounded half-away-from-zero to `decimals` (default 2) with trailing zeros
trimmed; a rounding carry promotes to the next unit (`999,999,999` →
`1 พันล้าน`). Values below `10⁶` fall back to the full reading. `*BigInt`
forms work at arbitrary scale, and `formatShort` takes the same
`thaiDigits:` flag as the other formatters (coefficient digits only).

### Baht text (บาทตัวอักษร)

`baht` takes an amount in **baht** (the usual unit); use `bahtSatang` for
sub-baht precision (1 baht = 100 satang), or `bahtFromString` for a decimal
string:

```dart
baht(100);                // หนึ่งร้อยบาทถ้วน  (100 baht)
baht(0);                  // ศูนย์บาทถ้วน
bahtSatang(2121);         // ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์ (21.21 baht)
bahtSatang(25);           // ยี่สิบห้าสตางค์
bahtFromString('21.21');  // ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์ (string-exact)
```

There is also `bahtFromDouble(double)` (and the `satangFromFloat` helper) for
convenience, but it is **lossy** — prefer satang or strings for anything that
must be exact.

### Formatting

```dart
formatInt(1234567); // 1,234,567
formatSatang(2121); // 21.21
formatThb(2121);    // ฿21.21
```

### Ordinals, fractions, and Buddhist-Era years

```dart
ordinal(21);    // ที่ยี่สิบเอ็ด
fraction(3, 4); // เศษสามส่วนสี่
year(2566);     // พุทธศักราชสองพันห้าร้อยหกสิบหก
ceToBe(2023);   // 2566
```

### Thai dates (เดือนไทย / วันไทย / ปี พ.ศ.)

```dart
final d = DateTime.utc(2024, 6, 5);
formatDate(d);     // 5 มิถุนายน 2567
formatDateAbbr(d); // 5 มิ.ย. 2567
formatDateFull(d); // วันพุธที่ 5 มิถุนายน พ.ศ. 2567
monthTh(6);        // มิถุนายน
weekdayTh(d);      // วันพุธ
buddhistYear(d);   // 2567

parseDate('วันพุธที่ 5 มิถุนายน พ.ศ. 2567'); // DateTime.utc(2024, 6, 5)
```

Dates use the Buddhist-Era year (Gregorian + 543). Wrap a formatted string with
`toThaiDigits` if you want Thai numerals (e.g. `๕ มิถุนายน ๒๕๖๗`).

> Note: Dart's `DateTime.weekday` is Monday=1 .. Sunday=7. `thainum` maps that
> internally to the correct Thai weekday name, so `weekdayTh(DateTime)` just
> works.

### Time of day and durations

```dart
final t = DateTime.utc(2024, 1, 1, 14, 30);
formatTime(t);  // สิบสี่นาฬิกาสามสิบนาที (formal)
formatClock(t); // บ่ายสองโมงครึ่ง (colloquial)
formatDuration(const Duration(minutes: 90)); // หนึ่งชั่วโมงสามสิบนาที
```

### EtMode — `เอ็ด` vs `หนึ่ง`

By default the library uses `EtMode.always`, the Royal-Institute-recommended
form where a trailing one is read `เอ็ด`. Use `EtMode.tensOnly` if you want a
trailing one to read `หนึ่ง` except in the tens place:

```dart
const plain = Speller(et: EtMode.tensOnly);
spell(101);         // หนึ่งร้อยเอ็ด   (default EtMode.always)
plain.spellInt(101); // หนึ่งร้อยหนึ่ง
```

`Speller` exposes `.spellInt`, `.spellBigInt`, `.spellDecimal`, `.baht`,
`.ordinal`, `.fraction`, and `.year`, so you can pick the `EtMode` once and reuse
it. Reverse parsing accepts **both** forms.

## A note on money and precision

Money is handled in **integer satang** (1 baht = 100 satang) or `BigInt`, never
`double`. This means there are no binary-floating-point rounding surprises in
your baht text. The `*FromFloat` / `*FromDouble` entry points are provided only
as a convenience and are documented as lossy — reach for the satang / string /
`BigInt` APIs whenever correctness matters.

## Performance — the *A8th engine* (v0.5.1+)

v0.5.1 ships an internal fast-path engine, nicknamed the **A8th engine**, that
makes `format*`, `parse*` and `extractNumbers` substantially faster **with
byte-identical output** (no API or behaviour change — guaranteed by an
exhaustive baseline differential over ~1.8M format cases and ~170k
parse/extract cases, plus the full 507-test suite).

The engine was selected by an internal **Perf-MAX competition**: ten optimizers
each implemented a different approach in an isolated worktree; all correct
candidates were benchmarked head-to-head on one machine, and **entry #8 won on
geometric-mean speedup** — hence *A8th* (credit to optimizer #8).

What it changes (all internal):

- **Tokenizer** — an integer index cursor with first-code-unit dispatch buckets
  replaces the per-token `substring` re-copy, so the parser no longer grows
  super-linearly (O(n²)) on long inputs.
- **`extractNumbers`** — index-cursor matching plus dropping a per-token list
  copy.
- **`format*`** — native-int code-unit buffers instead of a `BigInt` round-trip,
  with the `thaiDigits` conversion folded into the same pass (`int.minValue`
  keeps the exact `BigInt` fallback).

Measured on the Dart VM (median ns/op, lower is better):

| Operation | Before | After | Speedup |
|---|---:|---:|---:|
| `formatSatang(212100)` (money path) | 273 | 47 | **5.8×** |
| `formatThb(212100)` | 384 | 135 | **2.8×** |
| `formatInt(1234567)` | 183 | 57 | **3.2×** |
| `formatInt(-9876543210)` | 479 | 94 | **5.1×** |
| `formatInt(…, thaiDigits: true)` | 365 | 147 | **2.5×** |
| `extractNumbers` (~120 chars) | 26905 | 3725 | **7.2×** |
| `extractNumbers` (~1.2k chars) | 327248 | 38858 | **8.4×** |
| `parseInt('ยี่สิบเอ็ด')` | 650 | 358 | **1.8×** |
| `parseInt('หนึ่งล้านสองแสนสามหมื่น')` | 1227 | 675 | **1.8×** |
| `parseBigInt('หนึ่งล้านล้าน')` | 662 | 417 | **1.6×** |

≈ **3.3× geometric mean** across the benchmarked hot paths. The `format*` wins
are larger still on **dart2js / web**, where `BigInt` is software-emulated — the
A8th engine removes that round-trip on the common path. Benchmarks live under
[`benchmark/`](benchmark/) (`dart run benchmark/bench.dart`).

## License

[MIT](LICENSE) © 2026 MaIII (ultramcu)
