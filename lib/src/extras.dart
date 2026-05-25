import 'spell.dart';

/// Renders [n] as a Thai ordinal ("ที่" + the number).
///
///     ordinal(1);  // 'ที่หนึ่ง'
///     ordinal(21); // 'ที่ยี่สิบเอ็ด'
String ordinal(int n) => const Speller().ordinal(n);

/// Renders num/den as a Thai fraction ("เศษ" num "ส่วน" den). [den] is expected
/// to be non-zero.
///
///     fraction(1, 2); // 'เศษหนึ่งส่วนสอง'
///     fraction(3, 4); // 'เศษสามส่วนสี่'
String fraction(int num, int den) => const Speller().fraction(num, den);

/// Renders a Buddhist-Era year as Thai words prefixed with "พุทธศักราช".
///
///     year(2566); // 'พุทธศักราชสองพันห้าร้อยหกสิบหก'
String year(int be) => const Speller().year(be);

/// Converts a Common-Era (Gregorian) year to the Buddhist Era (+543).
int ceToBe(int ce) => ce + 543;

/// Converts a Buddhist-Era year to the Common Era (-543).
int beToCe(int be) => be - 543;

extension ExtrasSpeller on Speller {
  /// Renders [n] as a Thai ordinal.
  String ordinal(int n) => 'ที่${spellInt(n)}';

  /// Renders num/den as a Thai fraction.
  String fraction(int num, int den) =>
      'เศษ${spellInt(num)}ส่วน${spellInt(den)}';

  /// Renders a Buddhist-Era year as "พุทธศักราช" + the spelled number.
  String year(int be) => 'พุทธศักราช${spellInt(be)}';
}
