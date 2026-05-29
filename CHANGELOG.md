# Changelog

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
  test across the `3.0.0` and `stable` SDKs, plus a publish dry-run),
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
