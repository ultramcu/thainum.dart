# thainum

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

## Features

- **Thai numerals** — `toThaiDigits` / `toArabicDigits` (`101` ⇄ `๑๐๑`).
- **Spell numbers as Thai words** — `int`, `BigInt`, and decimals, correct to
  ล้านล้าน (10¹²) **and beyond**.
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

## License

[MIT](LICENSE) © 2026 MaIII (ultramcu)
