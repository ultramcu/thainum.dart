// Thin type-safe wrappers around an `int` (or `BigInt`) money amount.
//
// `FormData.clone()` and friends in untyped Dart APIs make it easy to pass a
// satang amount somewhere expecting baht — the resulting string is wrong but
// the program is wrong silently. Wrapping the amount in a one-field class
// gives the compiler enough information to catch that at the call site:
//
//     Baht(100).toBahtText()           // หนึ่งร้อยบาทถ้วน    (baht)
//     Satang(2121).toBahtText()        // ยี่สิบเอ็ดบาท…สตางค์ (satang)
//
// The wrappers are immutable and `const`-eligible, so `const Baht(100)` does
// not allocate. They implement `==` and `hashCode` by value so they work as
// `Map` keys / `Set` members.

import 'baht.dart';
import 'format.dart';

/// A whole-baht amount.
///
/// Use this when you want the compiler to enforce that the integer you have
/// is measured in baht (not satang). The amount is stored as an `int`; use
/// [BahtBigInt] for amounts beyond the `int` range.
class Baht {
  const Baht(this.value);

  /// The whole-baht amount.
  final int value;

  /// Spell this amount as Thai baht text: `Baht(100).toBahtText()` →
  /// `'หนึ่งร้อยบาทถ้วน'`.
  String toBahtText() => baht(value);

  @override
  bool operator ==(Object other) => other is Baht && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Baht($value)';
}

/// A satang amount (1 baht = 100 satang).
///
/// All methods preserve the exact integer satang value through the
/// conversion — there is no `double` round-trip. Use [SatangBigInt] for
/// amounts beyond the `int` range.
class Satang {
  const Satang(this.value);

  /// The amount in satang.
  final int value;

  /// Spell this amount as Thai baht text: `Satang(2121).toBahtText()` →
  /// `'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'`.
  String toBahtText() => bahtSatang(value);

  /// Decimal display in baht: `Satang(2121).toDecimal()` → `'21.21'`. With
  /// `thaiDigits: true` the digits render as Thai numerals: `'๒๑.๒๑'`.
  String toDecimal({bool thaiDigits = false}) =>
      formatSatang(value, thaiDigits: thaiDigits);

  /// `฿`-prefixed decimal display: `Satang(2121).toThb()` → `'฿21.21'`. With
  /// `thaiDigits: true` the digits render as Thai numerals: `'฿๒๑.๒๑'`.
  String toThb({bool thaiDigits = false}) =>
      formatThb(value, thaiDigits: thaiDigits);

  @override
  bool operator ==(Object other) => other is Satang && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Satang($value)';
}

/// A whole-baht amount stored as `BigInt`, for amounts that exceed the
/// `int` range (~9.2 × 10¹⁸ on 64-bit, ~2.1 × 10⁹ on the web).
class BahtBigInt {
  const BahtBigInt(this.value);

  /// The whole-baht amount.
  final BigInt value;

  /// Spell this amount as Thai baht text.
  String toBahtText() => bahtBigInt(value);

  @override
  bool operator ==(Object other) => other is BahtBigInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BahtBigInt($value)';
}

/// A satang amount stored as `BigInt`, for amounts that exceed the `int`
/// range. See [Satang] for the more common `int`-backed variant.
class SatangBigInt {
  const SatangBigInt(this.value);

  /// The amount in satang.
  final BigInt value;

  /// Spell this amount as Thai baht text.
  String toBahtText() => bahtSatangBigInt(value);

  @override
  bool operator ==(Object other) =>
      other is SatangBigInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SatangBigInt($value)';
}
