# Changelog

## 0.4.1

Additive release. All existing top-level functions keep byte-identical output.

- **`spellShort` / `formatShort` — abbreviated large-number reading (A5).**
  Renders a value `>= 1,000,000` with a single "สากล พัน/ล้าน" scale unit
  (units a factor of 1000 apart, starting at `10⁶`): `spellShort` reads it in
  Thai words, `formatShort` gives the Arabic-numeral display form. The
  coefficient is computed exactly from the decimal digit string (no
  floating-point), rounded half-away-from-zero to `decimals` (default 2) with
  trailing zeros trimmed, and a rounding carry promotes to the next unit
  (`999,999,999` → `1 พันล้าน`). Below `10⁶` both fall back to the full reading
  (`spell` / `formatInt`). `*BigInt` forms and `thaiDigits:` (coefficient only)
  are provided; `decimals < 0` throws `ArgumentError`. Plus the
  `int` / `BigInt` extensions `toThaiShortWords` and `toShortString`.

  ```dart
  spellShort(1500000);     // 'หนึ่งจุดห้าล้าน'
  formatShort(2300000000); // '2.3 พันล้าน'
  formatShort(50000000000);// '50 พันล้าน'   (scale units are 1000 apart)
  ```

## 0.4.0

Additive release. Existing top-level functions keep byte-identical default
output; every new capability is new API or opt-in.

- **`extractNumbers` — find Thai numbers in free text.** Scans left to right
  and returns a `List<NumberMatch>` (with `start`/`end` offsets into the
  source, `matched`, `value`, `isWord`, `isDigits`). Consumes the maximal valid
  number at each position — a run of Arabic/Thai digit characters, or the
  longest contiguous word-run the integer grammar accepts as one number.

  ```dart
  extractNumbers('ซื้อมา ๓ ชิ้น ราคาห้าร้อยบาท');
  // [ ๓ → 3 (isDigits), ห้าร้อย → 500 (isWord) ]
  ```

- **`parseDecimal` — inverse of `spellDecimal`.** Splits on `'จุด'`; the
  integer part is parsed normally and the fractional part is read digit-by-digit.
  Returns a canonical decimal `String`. Also `String.parseThaiDecimal()`.

  ```dart
  parseDecimal('สิบสองจุดสามสี่'); // '12.34'
  ```

- **Opt-in lenient / colloquial parsing.** `parseInt`, `parseBigInt`,
  `parseBaht` and `parseDecimal` gain `allowColloquial` (accept `'นึง'` as 1)
  and `lenient` (strip internal spaces, NBSP and zero-width characters) named
  parameters, both defaulting to `false`.

  ```dart
  parseInt('ร้อยนึง', allowColloquial: true); // 101
  parseInt('ยี่สิบ เอ็ด', lenient: true);      // 21
  ```

- **Thai National / Tax ID.** `isValidThaiId` (13-digit MOD-11 checksum),
  `isValidThaiTaxId`, `parseThaiId`, `formatThaiId` (`X-XXXX-XXXXX-XX-X`),
  `classifyThaiId` (`ThaiIdKind` from the leading digit, per DOPA) and
  `speakThaiId` (digit-by-digit). Matching `String` extensions.

  ```dart
  '1-1017-00230-70-8'.isValidThaiId(); // true
  ```

- **Percent reading & formatting.** `percent(value, {style})` reads a value as
  `'ร้อยละ…'` (`PercentStyle.royalRoiLa`, default) or `'…เปอร์เซ็นต์'`
  (`PercentStyle.colloquialPercent`); `formatPercent` gives the numeric display
  form (`'25%'`, `'25.5%'`). Plus `num.toThaiPercent()`.

  ```dart
  percent(25);        // 'ร้อยละยี่สิบห้า'
  formatPercent(25.5); // '25.5%'
  ```

- **More tests.** Per-module suites for spell, extras, date (format⇄parse),
  colloquial-clock boundaries, and durations, plus negative-path coverage for
  the new APIs.

## 0.3.0

Additive release. The existing top-level functions keep byte-identical default
output — every new capability is opt-in.

- **Non-throwing parsing (`tryParse*`).** `tryParseInt`, `tryParseBigInt`,
  `tryParseBaht` (in addition to the existing `parseInt` / … ) and
  `tryParseDate` return `null` on a `FormatException` instead of throwing.
  Matching `String` extensions: `tryParseThaiInt`, `tryParseThaiBigInt`,
  `tryParseThaiBaht`, `tryParseThaiDate`.

  ```dart
  tryParseInt('สิบสิบ');         // null
  'ยี่สิบเอ็ด'.tryParseThaiInt(); // 21
  ```

- **`speakDigits` — digit-by-digit reading (อ่านเรียงตัว).** Reads each digit
  as its own Thai word (the way phone/account numbers are read), not as a
  quantity. Accepts Arabic and Thai numerals; non-digits collapse to a single
  `separator`; `colloquialTwo: true` reads `2` as `'โท'`. Plus the
  `String.speakThaiDigits()` extension.

  ```dart
  speakDigits('2566');         // 'สอง ห้า หก หก'
  speakDigits('081-234-5678'); // 'ศูนย์ แปด หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด'
  ```

- **`thaiDigits:` flag on formatters and date helpers.** `formatInt`,
  `formatSatang`, `formatThb`, `formatDate`, `formatDateAbbr` and
  `formatDateFull` (and their extension methods, plus `Satang.toDecimal` /
  `Satang.toThb`) gain an optional `thaiDigits` parameter (default `false`).
  When true, only ASCII digits become Thai numerals — commas, the decimal
  point, the `฿` symbol, the `-` sign and labels like `พ.ศ.` stay ASCII.

  ```dart
  formatThb(2121, thaiDigits: true);   // '฿๒๑.๒๑'
  formatInt(1234567, thaiDigits: true); // '๑,๒๓๔,๕๖๗'
  ```

- **Trust signals.** Added a GitHub Actions CI workflow (format / analyze /
  test across the `3.1.0` and `stable` SDKs, plus a publish dry-run),
  declared the pure-Dart `platforms:` set, and added CI + pub.dev README
  badges. New test suites: round-trip property tests (seeded + boundaries,
  both `EtMode`s), a hand-checked spell golden table, and data-driven negative
  parse tests.

## 0.2.0

Receiver-style API and typed money wrappers. No behavioural change to the
existing top-level functions — they keep working, the new shapes are
additive.

- **Extension methods** on `int`, `BigInt`, `double`, `String`, `DateTime`,
  and `Duration`. Every top-level function now has a `toThaiXxx()`
  counterpart so it reads naturally in a call chain:

  ```dart
  21.toThaiWords();                      // 'ยี่สิบเอ็ด'
  '101'.toThaiDigits();                  // '๑๐๑'
  1234567.toThousandsString();           // '1,234,567'
  'ยี่สิบเอ็ด'.parseThaiInt();           // 21
  DateTime.utc(2024, 6, 5).toThaiDate(); // '5 มิถุนายน 2567'
  DateTime.utc(2024, 6, 5).buddhistYear; // 2567 (getter — property)
  const Duration(minutes: 90).toThaiText();
  ```

  Conversions are methods (`toXxx()`, parens); component accessors on
  `DateTime` (`buddhistYear`, `thaiMonthName`, `thaiWeekdayName`, …) are
  getters parallel to `DateTime.year` / `DateTime.month`.

- **Typed money wrappers** `Baht`, `Satang`, `BahtBigInt`, `SatangBigInt`.
  Each is a one-field `const`-eligible class with value-equality. Passing a
  satang amount where baht is expected now becomes a type error instead of
  a wrong invoice:

  ```dart
  const Baht(100).toBahtText();    // 'หนึ่งร้อยบาทถ้วน'
  const Satang(2121).toBahtText(); // 'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'
  const Satang(2121).toDecimal();  // '21.21'
  const Satang(2121).toThb();      // '฿21.21'
  ```

  `int.toBahtText()` (and the `BigInt` / `double` versions) interpret the
  receiver as whole baht — the unambiguous default. Use a `Satang(...)`
  wrapper when you have satang.

- All public extensions and wrappers are exported from
  `package:thainum/thainum.dart` — no extra import needed.

## 0.1.0

Initial release. A pure-Dart port of the `go-thainum` library — no Flutter and
no `intl` dependency (the Thai tables are bundled).

- **Thai numerals** — `toThaiDigits` / `toArabicDigits` convert between Arabic
  and Thai digits (`101` ⇄ `๑๐๑`) in mixed text.
- **Spell numbers as Thai words** — `spell(int)`, `spellBigInt(BigInt)`,
  `spellDecimal(String)`, correct to ล้านล้าน (10¹²) and beyond, with a
  selectable `EtMode` (`always` / `tensOnly`) via the `Speller` class.
- **Baht text (บาทตัวอักษร)** — `baht` (whole baht), `bahtSatang`,
  `bahtBigInt`, `bahtSatangBigInt`, `bahtFromString` (string-exact, 2-dp
  away-from-zero rounding), `satangFromFloat` and `bahtFromDouble`.
- **Formatting** — `formatInt`, `formatSatang`, `formatThb` (฿).
- **Reverse parsing (the flagship feature)** — `parseInt`, `parseBigInt`,
  `parseBaht`; accepts both เอ็ด and หนึ่ง forms and Thai or Arabic digits;
  throws `ThaiNumException` (a `FormatException`) on bad input.
- **Ordinals, fractions & Buddhist-Era years** — `ordinal`, `fraction`, `year`,
  plus `ceToBe` / `beToCe`.
- **Thai dates** — `monthTh` / `monthAbbrTh`, `weekdayTh` / `weekdayAbbrTh`,
  `buddhistYear`, `formatDate` / `formatDateAbbr` / `formatDateFull`, and
  `parseDate` (round-trips the formatters; BE → CE).
- **Thai time & durations** — `formatTime` (formal นาฬิกา), `formatClock`
  (colloquial ตี / โมง / ทุ่ม), and `formatDuration`.
