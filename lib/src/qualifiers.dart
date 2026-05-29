import 'exception.dart';
import 'spell.dart';

/// Prefixes a spelled number with `'ประมาณ'` ("approximately"):
///
///     thaiApprox(100); // 'ประมาณหนึ่งร้อย'
///     thaiApprox(21);  // 'ประมาณยี่สิบเอ็ด'
///     thaiApprox(-5);  // 'ประมาณลบห้า'
///
/// Works for any integer (the underlying [spell] handles sign and zero).
String thaiApprox(int n) => 'ประมาณ${spell(n)}';

/// Prefixes a spelled number with `'เกือบ'` ("nearly", just short of):
///
///     thaiNearly(100); // 'เกือบหนึ่งร้อย'
///     thaiNearly(20);  // 'เกือบยี่สิบ'
///
/// Works for any integer.
String thaiNearly(int n) => 'เกือบ${spell(n)}';

/// Reads an inclusive range `[a]` to `[b]` as `spell(a)` + `'ถึง'` + `spell(b)`:
///
///     thaiRange(10, 20); // 'สิบถึงยี่สิบ'
///     thaiRange(1, 5);   // 'หนึ่งถึงห้า'
///
/// The numbers are read exactly as [spell] renders them; [a] and [b] may be in
/// any order and may be negative (`thaiRange(-5, 5)` → `'ลบห้าถึงห้า'`). No
/// ordering or equality constraint is imposed — the words are simply joined by
/// `'ถึง'`.
String thaiRange(int a, int b) => '${spell(a)}ถึง${spell(b)}';

/// Reads `[n]` as `'…กว่า'` — "[n]-something", a value a little more than a
/// **round magnitude**.
///
///     thaiMoreThan(10);  // 'สิบกว่า'      (ten-something, i.e. 10–19)
///     thaiMoreThan(20);  // 'ยี่สิบกว่า'   (twenty-something)
///     thaiMoreThan(100); // 'หนึ่งร้อยกว่า'
///     thaiMoreThan(500); // 'ห้าร้อยกว่า'
///     thaiMoreThan(1000000); // 'หนึ่งล้านกว่า'
///
/// **Linguistic limit (important).** In Thai, `กว่า` attaches only to a *round
/// magnitude* — a number whose decimal form is a single non-zero leading digit
/// followed by zeros (10, 20, …, 90, 100, 200, …, 1000, 1000000, and so on).
/// `สิบกว่า` means "ten-something" (10–19); there is no well-formed `สิบเอ็ดกว่า`.
/// Applying `กว่า` to an arbitrary non-round number is not idiomatic, so this
/// function **rejects** such input: a value that is not a positive round
/// magnitude (at least 10) throws a [ThaiNumException] with
/// [ThaiNumError.notRoundMagnitude].
///
///     thaiMoreThan(11);  // throws (11 is not a round magnitude)
///     thaiMoreThan(150); // throws
///     thaiMoreThan(5);   // throws (single-digit, below 10)
///     thaiMoreThan(0);   // throws
///     thaiMoreThan(-10); // throws (must be positive)
String thaiMoreThan(int n) {
  if (!isRoundMagnitude(n)) {
    throw ThaiNumException(
      'thainum: thaiMoreThan expects a positive round magnitude '
      '(10, 20, …, 100, 1000, …), got $n',
      n.toString(),
      null,
      ThaiNumError.notRoundMagnitude,
    );
  }
  return '${spell(n)}กว่า';
}

/// True when [n] is a positive *round magnitude*: at least 10 and, in decimal,
/// a single non-zero leading digit followed only by zeros (10, 20, …, 90, 100,
/// 200, …, 1000, 10000, 1000000, …). This is exactly the domain on which the
/// Thai `กว่า` qualifier (see [thaiMoreThan]) is well-formed.
bool isRoundMagnitude(int n) {
  if (n < 10) return false;
  // Strip trailing zeros; what remains must be a single digit 1..9.
  var m = n;
  while (m % 10 == 0) {
    m ~/= 10;
  }
  return m >= 1 && m <= 9;
}

/// The qualifier words [thaiApprox], [thaiNearly] and [thaiMoreThan] produce,
/// for use with the [ThaiIntQualifierX] extension's
/// [ThaiIntQualifierX.toThaiQualified].
enum QualifierKind {
  /// `'ประมาณ'` — approximately ([thaiApprox]).
  approx,

  /// `'เกือบ'` — nearly ([thaiNearly]).
  nearly,

  /// `'…กว่า'` — round-magnitude "-something" ([thaiMoreThan]); only valid on a
  /// round magnitude (see [isRoundMagnitude]).
  moreThan,
}

/// Qualifier convenience methods on plain `int`, mirroring the top-level
/// [thaiApprox] / [thaiNearly] / [thaiRange] / [thaiMoreThan] functions.
extension ThaiIntQualifierX on int {
  /// `this` read as "approximately": `100.toThaiApprox()` →
  /// `'ประมาณหนึ่งร้อย'`. See [thaiApprox].
  String toThaiApprox() => thaiApprox(this);

  /// `this` read as "nearly": `100.toThaiNearly()` → `'เกือบหนึ่งร้อย'`. See
  /// [thaiNearly].
  String toThaiNearly() => thaiNearly(this);

  /// `this` read as a round-magnitude "-something": `10.toThaiMoreThan()` →
  /// `'สิบกว่า'`. Throws unless `this` is a round magnitude — see
  /// [thaiMoreThan].
  String toThaiMoreThan() => thaiMoreThan(this);

  /// Inclusive range from `this` to [other]: `10.toThaiRange(20)` →
  /// `'สิบถึงยี่สิบ'`. See [thaiRange].
  String toThaiRange(int other) => thaiRange(this, other);

  /// Applies the chosen [kind] qualifier to `this`. A convenience dispatcher
  /// over [thaiApprox] / [thaiNearly] / [thaiMoreThan].
  String toThaiQualified(QualifierKind kind) => switch (kind) {
        QualifierKind.approx => thaiApprox(this),
        QualifierKind.nearly => thaiNearly(this),
        QualifierKind.moreThan => thaiMoreThan(this),
      };
}
