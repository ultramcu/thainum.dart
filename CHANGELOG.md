# Changelog

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
