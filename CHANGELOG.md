# Changelog

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
