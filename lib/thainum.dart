/// A comprehensive Thai number toolkit: convert between Arabic and Thai digits,
/// spell numbers out as Thai words, render Thai Baht text (บาทไทย), format money,
/// format Thai dates and times (Buddhist-Era year with Thai month and weekday
/// names; formal and colloquial clock; durations), parse Thai dates back into a
/// [DateTime], and — the flagship — parse Thai number words back into integers.
///
///     toThaiDigits('2566');   // '๒๕๖๖'
///     spell(21);              // 'ยี่สิบเอ็ด'
///     baht(100);              // 100 baht -> 'หนึ่งร้อยบาทถ้วน'
///     bahtSatang(2121);       // 2121 satang -> 'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'
///     formatThb(2121);        // '฿21.21'
///     parseInt('ยี่สิบเอ็ด'); // 21
///
/// Every function above is also available as an extension method on its
/// receiver type, so the same calls read as:
///
///     '2566'.toThaiDigits();           // '๒๕๖๖'
///     21.toThaiWords();                // 'ยี่สิบเอ็ด'
///     Baht(100).toBahtText();          // 'หนึ่งร้อยบาทถ้วน'
///     Satang(2121).toBahtText();       // 'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'
///     Satang(2121).toThb();            // '฿21.21'
///     'ยี่สิบเอ็ด'.parseThaiInt();     // 21
///     DateTime(2024, 6, 5).toThaiDate(); // '5 มิถุนายน 2567'
///
/// Money values are handled in integer satang (1 baht = 100 satang) or via
/// [BigInt], never [double], so there are no rounding surprises. A documented
/// float entry point is provided for convenience. The [Baht] / [Satang] /
/// [BahtBigInt] / [SatangBigInt] wrappers make the unit a compile-time
/// guarantee — passing a satang amount where baht is expected becomes a
/// type error instead of a wrong invoice.
library;

export 'src/baht.dart';
export 'src/clock.dart';
export 'src/date.dart';
export 'src/exception.dart';
export 'src/extensions.dart';
export 'src/extras.dart';
export 'src/format.dart';
export 'src/money.dart';
export 'src/numerals.dart';
export 'src/parse.dart';
export 'src/percent.dart';
export 'src/short.dart';
export 'src/speak.dart';
export 'src/spell.dart' hide isDigits, splitDecimalInternal, DecimalParts;
export 'src/thai_id.dart';
