import 'spell.dart';

final BigInt _hundred = BigInt.from(100);

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
/// Baht text. The fractional part is rounded to two decimal places, away from
/// zero. Because the input is a string, no float rounding is involved.
String bahtFromString(String amount) => const Speller().bahtFromString(amount);

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

  /// Renders a decimal baht amount string as Thai Baht text.
  String bahtFromString(String amount) {
    final r = _parseToSatang(amount);
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
/// sign, rounding the fraction to two places away from zero.
_SatangResult _parseToSatang(String amount) {
  final d = splitDecimalInternal(amount);
  final bahtPart = d.intPart.isEmpty ? '0' : d.intPart;
  var sat = BigInt.parse(bahtPart) * _hundred;

  // Two-decimal satang with away-from-zero rounding on the third digit.
  var cents = 0;
  if (d.frac.isNotEmpty) {
    cents += (d.frac.codeUnitAt(0) - 0x30) * 10;
  }
  if (d.frac.length >= 2) {
    cents += d.frac.codeUnitAt(1) - 0x30;
  }
  if (d.frac.length >= 3 && d.frac.codeUnitAt(2) >= 0x35) {
    cents++; // round up
  }
  sat += BigInt.from(cents);
  return _SatangResult(d.neg, sat);
}
