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
import 'exception.dart';
import 'format.dart';

/// A whole-baht amount.
///
/// Use this when you want the compiler to enforce that the integer you have
/// is measured in baht (not satang). The amount is stored as an `int`; use
/// [BahtBigInt] for amounts beyond the `int` range.
class Baht implements Comparable<Baht> {
  const Baht(this.value);

  /// Reconstructs a [Baht] from its [toJson] wire form: an `int` (a JSON
  /// number with no fractional part is also accepted). Throws a
  /// [ThaiNumException] on any other shape.
  factory Baht.fromJson(Object? json) => Baht(_intFromJson(json, 'Baht'));

  /// The whole-baht amount.
  final int value;

  /// Spell this amount as Thai baht text: `Baht(100).toBahtText()` →
  /// `'หนึ่งร้อยบาทถ้วน'`.
  String toBahtText() => baht(value);

  /// Returns a copy with [value] replaced (the single field). `copyWith()`
  /// with no argument returns an equal value.
  Baht copyWith({int? value}) => Baht(value ?? this.value);

  /// The canonical JSON wire form of a [Baht]: the whole-baht amount as an
  /// `int`. Round-trips through [Baht.fromJson].
  int toJson() => value;

  /// Orders by the underlying whole-baht [value].
  @override
  int compareTo(Baht other) => value.compareTo(other.value);

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
class Satang implements Comparable<Satang> {
  const Satang(this.value);

  /// Reconstructs a [Satang] from its [toJson] wire form: an `int` (a JSON
  /// number with no fractional part is also accepted). Throws a
  /// [ThaiNumException] on any other shape.
  factory Satang.fromJson(Object? json) => Satang(_intFromJson(json, 'Satang'));

  /// The amount in satang.
  final int value;

  /// Spell this amount as Thai baht text: `Satang(2121).toBahtText()` →
  /// `'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'`.
  String toBahtText() => bahtSatang(value);

  /// Returns a copy with [value] replaced (the single field). `copyWith()`
  /// with no argument returns an equal value.
  Satang copyWith({int? value}) => Satang(value ?? this.value);

  /// The canonical JSON wire form of a [Satang]: the satang amount as an
  /// `int`. Round-trips through [Satang.fromJson].
  int toJson() => value;

  /// Orders by the underlying satang [value].
  @override
  int compareTo(Satang other) => value.compareTo(other.value);

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
class BahtBigInt implements Comparable<BahtBigInt> {
  const BahtBigInt(this.value);

  /// Reconstructs a [BahtBigInt] from its [toJson] wire form: a decimal
  /// `String`. An `int` is also accepted for convenience. Throws a
  /// [ThaiNumException] on any other shape.
  factory BahtBigInt.fromJson(Object? json) =>
      BahtBigInt(_bigIntFromJson(json, 'BahtBigInt'));

  /// The whole-baht amount.
  final BigInt value;

  /// Spell this amount as Thai baht text.
  String toBahtText() => bahtBigInt(value);

  /// Returns a copy with [value] replaced (the single field). `copyWith()`
  /// with no argument returns an equal value.
  BahtBigInt copyWith({BigInt? value}) => BahtBigInt(value ?? this.value);

  /// The canonical JSON wire form of a [BahtBigInt]: the value as a decimal
  /// `String`, because `BigInt` is not a JSON-native number type and can
  /// exceed the safe-integer range of a JSON parser. Round-trips through
  /// [BahtBigInt.fromJson].
  String toJson() => value.toString();

  /// Orders by the underlying whole-baht [value].
  @override
  int compareTo(BahtBigInt other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is BahtBigInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BahtBigInt($value)';
}

/// A satang amount stored as `BigInt`, for amounts that exceed the `int`
/// range. See [Satang] for the more common `int`-backed variant.
class SatangBigInt implements Comparable<SatangBigInt> {
  const SatangBigInt(this.value);

  /// Reconstructs a [SatangBigInt] from its [toJson] wire form: a decimal
  /// `String`. An `int` is also accepted for convenience. Throws a
  /// [ThaiNumException] on any other shape.
  factory SatangBigInt.fromJson(Object? json) =>
      SatangBigInt(_bigIntFromJson(json, 'SatangBigInt'));

  /// The amount in satang.
  final BigInt value;

  /// Spell this amount as Thai baht text.
  String toBahtText() => bahtSatangBigInt(value);

  /// Returns a copy with [value] replaced (the single field). `copyWith()`
  /// with no argument returns an equal value.
  SatangBigInt copyWith({BigInt? value}) => SatangBigInt(value ?? this.value);

  /// The canonical JSON wire form of a [SatangBigInt]: the value as a decimal
  /// `String`, because `BigInt` is not a JSON-native number type and can
  /// exceed the safe-integer range of a JSON parser. Round-trips through
  /// [SatangBigInt.fromJson].
  String toJson() => value.toString();

  /// Orders by the underlying satang [value].
  @override
  int compareTo(SatangBigInt other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is SatangBigInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SatangBigInt($value)';
}

/// Decodes the JSON wire form of an `int`-backed money wrapper.
///
/// Accepts an `int`, or a `double` / `num` that is mathematically an integer
/// (so a JSON `21.0` round-trips). Rejects fractional numbers, strings, and
/// any other shape. [type] names the wrapper for the error message.
int _intFromJson(Object? json, String type) {
  if (json is int) return json;
  if (json is double) {
    if (json.isFinite && json == json.truncateToDouble()) return json.toInt();
  }
  throw ThaiNumException(
    'thainum: $type.fromJson expects an integer satang value, got '
    '${json.runtimeType}',
    json,
    null,
    ThaiNumError.invalidNumber,
  );
}

/// Decodes the JSON wire form of a `BigInt`-backed money wrapper.
///
/// Accepts a decimal `String` (the canonical form) or an `int`. Rejects
/// `double`, malformed strings, and any other shape. [type] names the wrapper
/// for the error message.
BigInt _bigIntFromJson(Object? json, String type) {
  if (json is String) {
    final v = BigInt.tryParse(json.trim());
    if (v != null) return v;
  } else if (json is int) {
    return BigInt.from(json);
  }
  throw ThaiNumException(
    'thainum: $type.fromJson expects a decimal string value, got '
    '${json.runtimeType}',
    json,
    null,
    ThaiNumError.invalidNumber,
  );
}

// --- JsonConverter-shaped helpers ------------------------------------------
//
// These are plain dependency-free classes with `fromJson` / `toJson` methods
// laid out exactly like `package:json_annotation`'s `JsonConverter<T, S>`
// interface, but without importing that package (thainum stays zero-dep).
//
// Use them directly:
//
//     const c = SatangConverter();
//     final s = c.fromJson(jsonValue);   // Satang
//     final j = c.toJson(s);             // int
//
// or, in a json_serializable / freezed project, declare a converter that
// adopts the official interface and forwards to these:
//
//     class MySatangConverter implements JsonConverter<Satang, int> {
//       const MySatangConverter();
//       @override Satang fromJson(int json) => const SatangConverter()
//           .fromJson(json);
//       @override int toJson(Satang object) => const SatangConverter()
//           .toJson(object);
//     }
//
// The `@JsonKey`/`@…Converter()` annotation can then point at your adapter.

/// A `JsonConverter`-shaped adapter for [Baht]. Wire form is an `int`.
class BahtConverter {
  /// Creates a const converter.
  const BahtConverter();

  /// Decodes [json] (an `int`, or an integer-valued JSON number) into a [Baht].
  Baht fromJson(Object? json) => Baht.fromJson(json);

  /// Encodes [object] to its wire form (an `int`).
  int toJson(Baht object) => object.toJson();
}

/// A `JsonConverter`-shaped adapter for [Satang]. Wire form is an `int`.
class SatangConverter {
  /// Creates a const converter.
  const SatangConverter();

  /// Decodes [json] (an `int`, or an integer-valued JSON number) into a
  /// [Satang].
  Satang fromJson(Object? json) => Satang.fromJson(json);

  /// Encodes [object] to its wire form (an `int`).
  int toJson(Satang object) => object.toJson();
}

/// A `JsonConverter`-shaped adapter for [BahtBigInt]. Wire form is a decimal
/// `String`.
class BahtBigIntConverter {
  /// Creates a const converter.
  const BahtBigIntConverter();

  /// Decodes [json] (a decimal `String`, or an `int`) into a [BahtBigInt].
  BahtBigInt fromJson(Object? json) => BahtBigInt.fromJson(json);

  /// Encodes [object] to its wire form (a decimal `String`).
  String toJson(BahtBigInt object) => object.toJson();
}

/// A `JsonConverter`-shaped adapter for [SatangBigInt]. Wire form is a decimal
/// `String`.
class SatangBigIntConverter {
  /// Creates a const converter.
  const SatangBigIntConverter();

  /// Decodes [json] (a decimal `String`, or an `int`) into a [SatangBigInt].
  SatangBigInt fromJson(Object? json) => SatangBigInt.fromJson(json);

  /// Encodes [object] to its wire form (a decimal `String`).
  String toJson(SatangBigInt object) => object.toJson();
}
