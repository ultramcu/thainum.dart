# Changelog

## 0.5.2

Documentation only — no code change.

- Refreshed `example/example.dart` to cover the features added across v0.3–v0.5
  (`tryParse*`, `speakDigits`, the `thaiDigits:` flag, `extractNumbers`,
  `parseDecimal`, percent, qualifiers/idioms, typed money + JSON + rounding,
  `spellShort`/`formatShort`, Thai National/Tax ID, lottery and phone helpers,
  and structured error codes).

## 0.5.1

Internal performance pass (B8) — the **A8th engine** (the winning entry, #8 of
10, of an internal Perf-MAX optimizer competition; see the README "Performance"
section). **No API change, no behaviour change — output is byte-identical on
every path** (verified by an exhaustive baseline differential
over ~1.8M format cases and ~170k parse/extract cases, plus the full 507-test
suite incl. the round-trip property, golden, and go-thainum conformance vectors).

- **Tokenizer rewrite** — `_tokenize` now scans an integer index cursor with
  first-code-unit dispatch buckets instead of re-copying the tail via
  `substring` per token. This removes the super-linear (O(n²)) growth on long
  inputs (now linear) and speeds the whole `parse*` family ~1.6–1.9×.
- **`extractNumbers`** — index-cursor matching (no per-position `substring`) and
  dropping the per-token defensive list copy makes it **~7–8× faster** on free
  text.
- **`format*` native-int path** — `formatInt` / `formatSatang` / `formatThb`
  build the grouped string with native-int code-unit buffers instead of a
  `BigInt` round-trip, folding the `thaiDigits` conversion into the same pass.
  The money path (`formatSatang` / `formatThb`) is **~3–6× faster** on the VM
  and disproportionately faster on dart2js/web (where `BigInt` is emulated).
  `int.minValue` keeps the exact `BigInt` fallback.

## 0.5.0

Additive release. All existing top-level functions keep byte-identical output
and the same exception `message` / `toString()`.

- **Structured error codes + Thai messages + precise offsets (B6).** New
  `enum ThaiNumError` classifies every parser/speller/baht/decimal/date/ID
  failure. `ThaiNumException` gains a `ThaiNumError? code`, a `String get
  messageTh` (Thai-language wording per code, falling back to the English
  `message` when no code is set), and a `String describe()` that renders a
  caret under the offending token. The English `message`, `source` and
  `toString()` are unchanged, so existing `catch`/assert call sites keep
  working. Token offsets are now threaded through the tokenizer and point at
  the start of the bad token in the digit-normalized input; the latent
  `parseBaht` satang-part substring-offset bug is fixed (offsets are reported
  relative to the whole input, not the satang slice). Offsets are left `null`
  on the `lenient` path, where interior characters were removed.

- **Opt-in strict parse mode (B7).** `parseInt` / `parseBigInt` / `parseBaht` /
  `parseDecimal` accept `strict: false` (default). With `strict: true` a tens
  place fed by `หนึ่ง` (`หนึ่งสิบ` = 10) or by a plain `สอง` written instead of
  `ยี่` (`สองสิบ` = 20) throws `ThaiNumException` with
  `ThaiNumError.nonStandardTensDigit`. The default (lenient) path is unchanged
  and remains round-trip-safe; canonical forms (`สิบ`, `ยี่สิบ`, `ยี่สิบเอ็ด`)
  still parse under `strict`.

- **Approximate / range qualifiers (B2).** New `thaiApprox(n)` → `'ประมาณ…'`,
  `thaiNearly(n)` → `'เกือบ…'`, `thaiRange(a, b)` → `'…ถึง…'`, and
  `thaiMoreThan(n)` → `'…กว่า'` ("-something"), composed on `spell`. `กว่า` is
  well-formed only on a *round magnitude* — a value `>= 10` that is a single
  non-zero leading digit followed by zeros (10, 20, …, 100, 500, 1000,
  1000000, …); `thaiMoreThan` rejects anything else with
  `ThaiNumError.notRoundMagnitude` (a new error code, with a Thai message). Plus
  the predicate `isRoundMagnitude(n)`, an `enum QualifierKind`, and `int`
  extensions `toThaiApprox` / `toThaiNearly` / `toThaiMoreThan` / `toThaiRange` /
  `toThaiQualified`.

  ```dart
  thaiApprox(100);   // 'ประมาณหนึ่งร้อย'
  thaiNearly(100);   // 'เกือบหนึ่งร้อย'
  thaiRange(10, 20); // 'สิบถึงยี่สิบ'
  thaiMoreThan(10);  // 'สิบกว่า'   (thaiMoreThan(11) throws — not a round magnitude)
  ```

- **ครึ่ง / โหล / คู่ idioms (B3, opt-in, narrow).** `spellDecimal` gains an
  optional `useHalf` flag (default `false` → output byte-identical) so an exact
  `.5` fraction reads `'ครึ่ง'`: `spellDecimal('2.5', useHalf: true)` →
  `'สองครึ่ง'`, `spellDecimal('0.5', useHalf: true)` → `'ครึ่ง'`. A non-`.5`
  fraction still reads digit-by-digit. New unit-word surface
  `enum QuantityUnit` with `quantityWord(unit)` (→ `'ครึ่ง'`/`'คู่'`/`'โหล'`/
  `'กุรุส'`) and `quantityValue(unit)` (→ `0.5`/`2`/`12`/`144`). A focused,
  **separate** parse helper `parseQuantity(s)`
  (returns `num`) recognises a bare `'ครึ่ง'`/`'คู่'`/`'โหล'`/`'กุรุส'`, a Thai
  integer reading, and an integer + trailing `'ครึ่ง'` (`'สองครึ่ง'` → `2.5`);
  it does **not** entangle the integer grammar or attempt general ลักษณนาม
  classifiers (so `'สองโหล'` is intentionally unsupported). Plus
  `parseHalfBaht('ครึ่งบาท')` → `50` satang.

- **Value-type completeness + JSON on the money wrappers (B4).** `Baht`,
  `Satang`, `BahtBigInt` and `SatangBigInt` now `implements Comparable<T>`
  (`compareTo` by the underlying value, so they sort and compare directly),
  gain a single-field `copyWith({value})`, and gain a `toJson()` / factory
  `fromJson(Object?)` JSON round-trip. The wire form is documented and explicit:
  `Baht`/`Satang` emit an `int`; `BahtBigInt`/`SatangBigInt` emit the value as a
  decimal `String` (a `BigInt` is not a JSON-native number). `fromJson` accepts
  the canonical form (plus an integer-valued JSON number for the `int` wrappers
  and a bare `int` for the `BigInt` wrappers) and throws `ThaiNumException`
  (`ThaiNumError.invalidNumber`, a `FormatException`) on any other shape.
  Four dependency-free `JsonConverter`-shaped adapter classes —
  `BahtConverter`, `SatangConverter`, `BahtBigIntConverter`,
  `SatangBigIntConverter` — expose `fromJson`/`toJson` laid out exactly like
  `package:json_annotation`'s `JsonConverter<T, S>` so json_serializable /
  freezed users can `implements JsonConverter<...>` and forward to them (or use
  them directly), without thainum taking any new dependency. The existing
  `==` / `hashCode` / `toString` behaviour is unchanged.

- **Selectable baht rounding mode (B5).** `bahtFromString` gains an optional
  `rounding` parameter — `enum SatangRounding { halfAwayFromZero, halfEven,
  truncate, ceil, floor }` — applied to the fractional tail when the decimal
  string carries more than two decimal places. The default
  `halfAwayFromZero` reproduces the previous behaviour byte-identically (an
  independent oracle over the existing inputs guards this). The rounding
  decision is made entirely from the digit string with integer arithmetic — no
  `double` is ever involved, so arbitrarily long fractions
  (`'0.005000…0001'`) round correctly. `halfEven` is banker's rounding for
  financial reporting (`'0.005'` → `0` satang, `'0.015'` → `2`); `truncate`
  rounds toward zero; `ceil`/`floor` round toward ±∞ (sign-aware on negative
  amounts).

- **Thai lottery reading helpers (B9).** New `lib/src/lottery.dart` (reading +
  date only, no prize-checking and no data): `speakLotteryNumber(sixDigits)`
  reads a six-digit prize number digit-by-digit (อ่านเรียงตัว) via
  `speakDigits`, and `speakTwoDigit` / `speakThreeDigit` read the เลขท้าย 2/3
  ตัว. All three accept Arabic or Thai numerals, expose the `separator` /
  `colloquialTwo` options, and throw `ThaiNumException` if the length is wrong
  or a non-digit is present. Plus a draw-date convenience —
  `isLotteryDrawDate(DateTime)` and `lotteryDrawDates(year, month)` — for the
  regular 1st-and-16th Thai Government Lottery schedule (documented as the
  regular schedule, not the rare holiday shifts).

  ```dart
  speakLotteryNumber('123456'); // 'หนึ่ง สอง สาม สี่ ห้า หก'
  speakTwoDigit('07');          // 'ศูนย์ เจ็ด'
  isLotteryDrawDate(DateTime(2024, 6, 16)); // true
  ```

- **Thai phone formatting + spoken reading (B10).** New `lib/src/phone.dart`:
  `formatThaiPhone` groups a 10-digit mobile number `3-3-4`
  (`'0812345678'` → `'081-234-5678'`) and a 9-digit landline `2-3-4`
  (best-effort, since provincial area-code lengths vary); `thaiPhoneKind`
  classifies into `enum ThaiPhoneKind { mobile, landline, tollFree, shortCode,
  unknown }` conservatively (unknown when unsure); `normalizeThaiPhone` returns
  E.164 `+66…` (drops a single trunk `0`); and `speakThaiPhone` reads
  digit-by-digit via `speakDigits` (so `colloquialTwo: true` reads `2` as
  `'โท'`). All accept separators, spaces, Thai numerals and a `+66` country
  code. Matching `String` extensions (`'0812345678'.formatThaiPhone()`, etc.).

  ```dart
  formatThaiPhone('0812345678');  // '081-234-5678'
  thaiPhoneKind('021234567');     // ThaiPhoneKind.landline
  normalizeThaiPhone('0812345678'); // '+66812345678'
  ```

- **`thainum` CLI (B1).** New `bin/thainum.dart` — `dart run thainum:thainum
  <cmd>` or, after `dart pub global activate thainum`, `thainum <cmd>`.
  Subcommands `spell <int>`, `baht <amount>` (int or decimal string),
  `parse <thai-words>`, `digits <int>`, `date <YYYY-MM-DD>`. Flags
  `--et=always|tensOnly` (for `spell`), `--full` / `--abbr` (for `date`),
  `--json` (emit a small JSON object), and `--help`. The argument parser is
  hand-rolled — **no `package:args`**, so the package graph stays
  dependency-free — and the CLI is a thin layer over the public API only. The
  command logic is a testable `runCli(List<String>) → CliResult` (output +
  exit code) so it is driven directly from tests; unknown commands / bad input
  exit non-zero and `ThaiNumException` is caught and printed cleanly.

  ```sh
  thainum spell 101                 # หนึ่งร้อยเอ็ด
  thainum spell 101 --et=tensOnly   # หนึ่งร้อยหนึ่ง
  thainum baht 21.21                # ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์
  thainum parse ยี่สิบเอ็ด --json   # {"value": "21"}
  thainum date 2024-06-05 --full    # วันพุธที่ 5 มิถุนายน พ.ศ. 2567
  ```

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
