import 'spell.dart';

/// How a percentage value is read aloud in Thai.
enum PercentStyle {
  /// The Royal-Institute / legal form: the prefix `'ร้อยละ'` followed by the
  /// spelled number (`'ร้อยละยี่สิบห้า'`). This is the form used in laws,
  /// contracts and official documents.
  royalRoiLa,

  /// The everyday/colloquial form: the spelled number followed by the loanword
  /// `'เปอร์เซ็นต์'` (`'ยี่สิบห้าเปอร์เซ็นต์'`).
  colloquialPercent,
}

/// Reads a percentage [value] in Thai words.
///
///     percent(25);                                       // 'ร้อยละยี่สิบห้า'
///     percent(25.5);                                     // 'ร้อยละยี่สิบห้าจุดห้า'
///     percent(25, style: PercentStyle.colloquialPercent) // 'ยี่สิบห้าเปอร์เซ็นต์'
///
/// When [value] is a whole number it is spelled with [spell]; otherwise the
/// decimal is spelled with [spellDecimal] via `value.toString()`.
///
/// **Float caveat.** Passing a `double` is subject to the usual binary
/// floating-point string caveat (e.g. `0.1 + 0.2` does not stringify as
/// `'0.3'`). For exact output pass an `int`, or a value whose `toString()`
/// gives the decimal you intend.
String percent(num value, {PercentStyle style = PercentStyle.royalRoiLa}) {
  final spelled = _spellValue(value);
  const suffix = 'เปอร์เซ็นต์';
  switch (style) {
    case PercentStyle.royalRoiLa:
      return 'ร้อยละ$spelled';
    case PercentStyle.colloquialPercent:
      return '$spelled$suffix';
  }
}

/// Spells a percentage value: integers (and whole doubles) via [spell],
/// fractional values via [spellDecimal].
String _spellValue(num value) {
  if (value is int) return spell(value);
  if (value == value.truncateToDouble()) {
    return spell(value.toInt());
  }
  return spellDecimal(value.toString());
}

/// Numeric display form of a percentage: integer → `'25%'`, fractional →
/// trimmed decimal + `'%'` (no trailing zeros).
///
///     formatPercent(25);   // '25%'
///     formatPercent(25.5); // '25.5%'
///     formatPercent(25.0); // '25%'
String formatPercent(num value) {
  if (value is int) return '$value%';
  if (value == value.truncateToDouble()) {
    return '${value.toInt()}%';
  }
  // Trim trailing zeros from the fractional part (and a dangling dot).
  var s = value.toString();
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return '$s%';
}
