// A tour of `thainum`. Run with: dart run example/example.dart
// (There is also a command-line tool: dart run thainum:thainum --help)
import 'package:thainum/thainum.dart';

void main() {
  // ── Thai numerals ────────────────────────────────────────────────────────
  print(toThaiDigits('101')); // ๑๐๑
  print(toArabicDigits('๑๐๑')); // 101

  // ── Spell numbers as Thai words ──────────────────────────────────────────
  print(spell(21)); // ยี่สิบเอ็ด
  print(spell(101)); // หนึ่งร้อยเอ็ด
  print(spellBigInt(BigInt.from(1000000000000))); // หนึ่งล้านล้าน
  print(spellDecimal('12.34')); // สิบสองจุดสามสี่
  print(spellDecimal('2.5', useHalf: true)); // สองครึ่ง

  // Abbreviated large numbers (v0.4.1) — สากล พัน/ล้าน scale units.
  print(spellShort(1500000)); // หนึ่งจุดห้าล้าน
  print(formatShort(50000000000)); // 50 พันล้าน

  // ── Baht text (บาทตัวอักษร) ───────────────────────────────────────────────
  print(baht(100)); // หนึ่งร้อยบาทถ้วน
  print(bahtSatang(2121)); // ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์
  print(bahtFromString('21.21')); // ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์

  // Selectable rounding (v0.5.0) — exact, no float. 0.015 baht = 1.5 satang;
  // half-even rounds it up to 2 satang.
  print(
      bahtFromString('0.015', rounding: SatangRounding.halfEven)); // สองสตางค์

  // Typed money wrappers + JSON (v0.2.0 / v0.5.0).
  print(const Satang(2121).toThb()); // ฿21.21
  print(const Satang(2121).toJson()); // 2121

  // ── Formatting ────────────────────────────────────────────────────────────
  print(formatInt(1234567)); // 1,234,567
  print(formatThb(2121)); // ฿21.21
  print(formatThb(2121, thaiDigits: true)); // ฿๒๑.๒๑

  // ── Reverse parsing — the flagship ───────────────────────────────────────
  print(parseInt('ยี่สิบเอ็ด')); // 21
  print(parseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์')); // 2121
  print(parseBigInt('หนึ่งล้านล้านล้าน')); // 1000000000000000000
  print(parseDecimal('สิบสองจุดสามสี่')); // 12.34

  // Non-throwing variants (v0.3.0).
  print(tryParseInt('ยี่สิบเอ็ด')); // 21
  print(tryParseInt('สิบสิบ')); // null

  // Opt-in lenient / colloquial parsing (v0.4.0).
  print(parseInt('ร้อยนึง', allowColloquial: true)); // 101
  print(parseInt('ยี่สิบ เอ็ด', lenient: true)); // 21

  // Find every number embedded in free text (v0.4.0).
  for (final m in extractNumbers('ซื้อมา ๓ ชิ้น ราคาห้าร้อยบาท')) {
    print('${m.matched} -> ${m.value}'); // ๓ -> 3 ; ห้าร้อย -> 500
  }

  // Read digits one by one (v0.3.0) — phone / account / PIN.
  print(speakDigits('081-234-5678'));
  // ศูนย์ แปด หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด

  // ── Percent (v0.4.0) ──────────────────────────────────────────────────────
  print(percent(25)); // ร้อยละยี่สิบห้า
  print(percent(25,
      style: PercentStyle.colloquialPercent)); // ยี่สิบห้าเปอร์เซ็นต์
  print(formatPercent(25.5)); // 25.5%

  // ── Qualifiers & idioms (v0.5.0) ──────────────────────────────────────────
  print(thaiApprox(100)); // ประมาณหนึ่งร้อย
  print(thaiRange(10, 20)); // สิบถึงยี่สิบ
  print(quantityWord(QuantityUnit.dozen)); // โหล
  print(parseQuantity('สองครึ่ง')); // 2.5

  // ── Thai National / Tax ID (v0.4.0) ──────────────────────────────────────
  print('1-1017-00230-70-8'.isValidThaiId()); // true
  print(formatThaiId('1101700230708')); // 1-1017-00230-70-8
  print(classifyThaiId('1101700230708').name); // thaiBornRegisteredOnTime

  // ── Lottery & phone (v0.5.0) ─────────────────────────────────────────────
  print(speakLotteryNumber('123456'));
  // หนึ่ง สอง สาม สี่ ห้า หก
  print(formatThaiPhone('0812345678')); // 081-234-5678
  print(thaiPhoneKind('0812345678').name); // mobile
  print(normalizeThaiPhone('0812345678')); // +66812345678

  // ── EtMode — เอ็ด vs หนึ่ง ────────────────────────────────────────────────
  const plain = Speller(et: EtMode.tensOnly);
  print(plain.spellInt(101)); // หนึ่งร้อยหนึ่ง

  // ── Ordinals, fractions, Buddhist-Era years ──────────────────────────────
  print(ordinal(21)); // ที่ยี่สิบเอ็ด
  print(fraction(3, 4)); // เศษสามส่วนสี่
  print(year(2566)); // พุทธศักราชสองพันห้าร้อยหกสิบหก

  // ── Thai dates, time and durations ───────────────────────────────────────
  final d = DateTime.utc(2024, 6, 5);
  print(formatDateFull(d)); // วันพุธที่ 5 มิถุนายน พ.ศ. 2567
  print(parseDate('5 มิถุนายน 2567')); // 2024-06-05 00:00:00.000Z
  final t = DateTime.utc(2024, 1, 1, 14, 30);
  print(formatClock(t)); // บ่ายสองโมงครึ่ง
  print(formatDuration(const Duration(minutes: 90))); // หนึ่งชั่วโมงสามสิบนาที

  // ── Structured errors (v0.5.0) — code + Thai message ─────────────────────
  try {
    parseInt('สิบสิบ');
  } on ThaiNumException catch (e) {
    print(e.code); // ThaiNumError.misplacedPlaceWord
    print(e.messageTh); // thainum: คำบอกหลักวางผิดตำแหน่ง
  }
}
