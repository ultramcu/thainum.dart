import 'spell.dart';

final BigInt _hundred = BigInt.from(100);

/// How the fractional tail beyond two decimal places is resolved when a decimal
/// baht string is converted to integer satang.
///
/// A baht amount has at most two fractional digits of precision (one satang =
/// 0.01 baht). When the input string carries more digits than that
/// (`'12.345'`, `'0.005'`), the digits beyond the second must be folded into
/// the satang value somehow. The mode decides how.
///
/// The conversion is done entirely on the digit string with integer
/// arithmetic — there is no `double` anywhere on the path, so none of these
/// modes can introduce binary-floating-point error.
///
/// Which mode to use is an accounting/legal question, not a numeric one:
///
/// * [halfAwayFromZero] — the default and the historical behaviour. `0.005` →
///   1 satang, `-0.005` → -1 satang. Matches everyday "round the receipt"
///   intuition and Go's `math.Round`.
/// * [halfEven] — banker's rounding (round-half-to-even). `0.005` → 0 satang,
///   `0.015` → 2 satang. Reduces cumulative bias over many roundings and is
///   the IEEE-754 default; common in financial reporting and required by some
///   accounting standards.
/// * [truncate] — drop the extra digits (round toward zero). `0.009` → 0
///   satang, `-0.009` → 0 satang. Used where the law forbids rounding *up*
///   against the payer.
/// * [ceil] — round toward positive infinity. `0.001` → 1 satang, `-0.009` →
///   0 satang.
/// * [floor] — round toward negative infinity. `0.009` → 0 satang, `-0.001` →
///   -1 satang.
enum SatangRounding {
  /// Round half away from zero (the default; historical behaviour).
  halfAwayFromZero,

  /// Banker's rounding: round half to the nearest even satang.
  halfEven,

  /// Drop the extra fractional digits (round toward zero).
  truncate,

  /// Round toward positive infinity.
  ceil,

  /// Round toward negative infinity.
  floor,
}

/// Renders a whole-baht amount as Thai Baht text, using the default [EtMode].
/// The argument is in BAHT (the unit people normally use); for sub-baht
/// precision use [bahtSatang] (satang) or [bahtFromString] ("21.21").
///
///     baht(100); // 'หนึ่งร้อยบาทถ้วน'
///     baht(21);  // 'ยี่สิบเอ็ดบาทถ้วน'
///     baht(-5);  // 'ลบห้าบาทถ้วน'
String baht(int b) => const Speller().baht(b);

/// Renders an amount given in satang (1 baht = 100 satang) as Thai Baht text.
/// Use this when you need sub-baht precision.
///
///     bahtSatang(2121); // 'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'
///     bahtSatang(25);   // 'ยี่สิบห้าสตางค์'
///     bahtSatang(0);    // 'ศูนย์บาทถ้วน'
String bahtSatang(int satang) => const Speller().bahtSatang(satang);

/// Renders an arbitrarily large whole-baht amount as Thai Baht text.
String bahtBigInt(BigInt b) => const Speller().bahtBigInt(b);

/// Renders an arbitrarily large satang amount as Thai Baht text.
String bahtSatangBigInt(BigInt satang) =>
    const Speller().bahtSatangBigInt(satang);

/// Renders a decimal baht amount written as a string (e.g. "21.21") as Thai
/// Baht text. The fractional part is rounded to two decimal places using
/// [rounding] (default [SatangRounding.halfAwayFromZero]). Because the input is
/// a string, no float rounding is involved.
String bahtFromString(String amount,
        {SatangRounding rounding = SatangRounding.halfAwayFromZero}) =>
    const Speller().bahtFromString(amount, rounding: rounding);

/// Convenience wrapper that renders a float baht amount. It is lossy: the
/// float is converted to satang first. Prefer [baht] (whole baht), [bahtSatang]
/// (satang) or [bahtFromString] for money-grade input.
String bahtFromDouble(double amount) => const Speller().bahtFromDouble(amount);

/// Converts a baht amount given as a double into satang, rounding to the
/// nearest satang (half away from zero). Float money is inherently imprecise;
/// prefer integer satang or [bahtFromString] for exact input.
///
///     satangFromFloat(21.21); // 2121
///     satangFromFloat(0.5);   // 50
int satangFromFloat(double b) {
  // Round half away from zero (Dart's double.round() rounds half away from
  // zero, matching Go's math.Round).
  return (b * 100).round();
}

extension BahtSpeller on Speller {
  /// Renders a whole-baht amount as Thai Baht text. Thin wrapper over
  /// [bahtSatang] (baht × 100).
  String baht(int b) => bahtSatangBigInt(BigInt.from(b) * _hundred);

  /// Renders a whole-baht amount (big) as Thai Baht text.
  String bahtBigInt(BigInt b) => bahtSatangBigInt(b * _hundred);

  /// Renders a satang amount as Thai Baht text.
  String bahtSatang(int satang) {
    final neg = satang < 0;
    final mag = BigInt.from(satang).abs();
    final out = _bahtFromBig(mag);
    return neg ? 'ลบ$out' : out;
  }

  /// Renders an arbitrarily large satang amount as Thai Baht text.
  String bahtSatangBigInt(BigInt satang) {
    final neg = satang.sign < 0;
    final out = _bahtFromBig(satang.abs());
    return neg ? 'ลบ$out' : out;
  }

  /// Renders a non-negative satang magnitude.
  String _bahtFromBig(BigInt mag) {
    final b = mag ~/ _hundred;
    final sat = (mag % _hundred).toInt();
    return _bahtParts(b, sat);
  }

  /// Assembles the baht text from a non-negative baht count and a satang value
  /// in 0..99.
  String _bahtParts(BigInt b, int sat) {
    final bahtZero = b.sign == 0;
    if (bahtZero && sat == 0) {
      return '${numberThai[0]}บาทถ้วน'; // ศูนย์บาทถ้วน
    }
    var out = '';
    if (!bahtZero) {
      out = '${spellBigInt(b)}บาท';
    }
    if (sat == 0) {
      return '$outถ้วน';
    }
    return '$out${spellGroup(sat)}สตางค์';
  }

  /// Renders a decimal baht amount string as Thai Baht text, rounding the
  /// fractional part to two places with [rounding].
  String bahtFromString(String amount,
      {SatangRounding rounding = SatangRounding.halfAwayFromZero}) {
    final r = _parseToSatang(amount, rounding);
    final out = _bahtFromBig(r.satang);
    if (r.neg && r.satang.sign != 0) {
      return 'ลบ$out';
    }
    return out;
  }

  /// Renders a float baht amount (lossy). Converts the amount to satang via
  /// [satangFromFloat] and then defers to [bahtSatang].
  String bahtFromDouble(double amount) => bahtSatang(satangFromFloat(amount));
}

/// A sign + non-negative satang magnitude.
class _SatangResult {
  _SatangResult(this.neg, this.satang);
  final bool neg;
  final BigInt satang;
}

/// Converts a decimal baht string to a non-negative satang magnitude plus a
/// sign, rounding the fraction to two places with [rounding].
///
/// All arithmetic is done on the digit string: `cents` is the truncated
/// two-digit satang magnitude, and a single `+1` increment is decided from the
/// discarded tail's position relative to one half-satang. No `double` is used,
/// so no mode can introduce binary-floating-point error.
_SatangResult _parseToSatang(String amount, SatangRounding rounding) {
  final d = splitDecimalInternal(amount);
  final bahtPart = d.intPart.isEmpty ? '0' : d.intPart;
  var sat = BigInt.parse(bahtPart) * _hundred;

  // Truncated two-decimal satang magnitude (toward zero), 0..99.
  var cents = 0;
  if (d.frac.isNotEmpty) {
    cents += (d.frac.codeUnitAt(0) - 0x30) * 10;
  }
  if (d.frac.length >= 2) {
    cents += d.frac.codeUnitAt(1) - 0x30;
  }

  // Classify the discarded tail (fractional digits at index 2 and beyond):
  //   0  → remainder exactly zero (nothing was dropped)
  //  -1  → remainder strictly below half a satang
  //   1  → remainder strictly above half a satang
  //   2  → remainder exactly half a satang ("5" then all zeros)
  final cmp = _compareTailToHalf(d.frac);

  var roundUp = false;
  switch (rounding) {
    case SatangRounding.halfAwayFromZero:
      // Round up on >= half (the historical behaviour: third digit >= '5').
      roundUp = cmp == 1 || cmp == 2;
    case SatangRounding.halfEven:
      // Round up on > half; on exactly half, only if it makes cents even.
      roundUp = cmp == 1 || (cmp == 2 && cents.isOdd);
    case SatangRounding.truncate:
      roundUp = false;
    case SatangRounding.ceil:
      // Toward +inf: a positive amount with any remainder rounds its
      // magnitude up; a negative amount truncates its magnitude.
      roundUp = !d.neg && cmp != 0;
    case SatangRounding.floor:
      // Toward -inf: a negative amount with any remainder rounds its
      // magnitude up; a positive amount truncates its magnitude.
      roundUp = d.neg && cmp != 0;
  }
  if (roundUp) cents++;

  sat += BigInt.from(cents);
  return _SatangResult(d.neg, sat);
}

/// Compares the discarded fractional tail (digits at index 2 and beyond of
/// [frac]) to one half-satang. Returns `0` for an exactly-zero remainder, `-1`
/// for below half, `1` for above half, and `2` for exactly half.
int _compareTailToHalf(String frac) {
  if (frac.length < 3) return 0;
  final firstCode = frac.codeUnitAt(2);
  if (firstCode < 0x35) {
    // First dropped digit < '5'. The remainder is below half unless the digit
    // is itself zero with no later non-zero digit — either way it is < half,
    // but only count it as a true zero remainder when nothing non-zero remains.
    for (var i = 2; i < frac.length; i++) {
      if (frac.codeUnitAt(i) != 0x30) return -1;
    }
    return 0;
  }
  if (firstCode > 0x35) return 1; // first dropped digit > '5' → above half
  // First dropped digit == '5': exactly half unless a later digit is non-zero.
  for (var i = 3; i < frac.length; i++) {
    if (frac.codeUnitAt(i) != 0x30) return 1;
  }
  return 2;
}
