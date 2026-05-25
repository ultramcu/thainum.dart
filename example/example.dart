import 'package:thainum/thainum.dart';

void main() {
  // Thai numerals
  print(toThaiDigits('101')); // ๑๐๑
  print(toArabicDigits('๑๐๑')); // 101

  // Spell numbers as Thai words
  print(spell(21)); // ยี่สิบเอ็ด
  print(spell(101)); // หนึ่งร้อยเอ็ด
  print(spellBigInt(BigInt.from(1000000000000))); // หนึ่งล้านล้าน
  print(spellDecimal('12.34')); // สิบสองจุดสามสี่

  // Baht text (บาทตัวอักษร)
  print(baht(100)); // หนึ่งร้อยบาทถ้วน
  print(bahtSatang(2121)); // ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์
  print(bahtSatang(25)); // ยี่สิบห้าสตางค์
  print(bahtFromString('21.21')); // ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์

  // Formatting
  print(formatInt(1234567)); // 1,234,567
  print(formatSatang(2121)); // 21.21
  print(formatThb(2121)); // ฿21.21

  // Reverse parsing — the flagship feature
  print(parseInt('ยี่สิบเอ็ด')); // 21
  print(parseBaht('ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์')); // 2121
  print(parseBigInt('หนึ่งล้านล้านล้าน')); // 1000000000000000000

  // Choose the EtMode once and reuse it.
  const plain = Speller(et: EtMode.tensOnly);
  print(plain.spellInt(101)); // หนึ่งร้อยหนึ่ง

  // Ordinals, fractions, Buddhist-Era years
  print(ordinal(21)); // ที่ยี่สิบเอ็ด
  print(fraction(3, 4)); // เศษสามส่วนสี่
  print(year(2566)); // พุทธศักราชสองพันห้าร้อยหกสิบหก

  // Thai dates
  final d = DateTime.utc(2024, 6, 5);
  print(formatDate(d)); // 5 มิถุนายน 2567
  print(formatDateFull(d)); // วันพุธที่ 5 มิถุนายน พ.ศ. 2567
  print(parseDate('5 มิถุนายน 2567')); // 2024-06-05 00:00:00.000Z

  // Time of day and durations
  final t = DateTime.utc(2024, 1, 1, 14, 30);
  print(formatTime(t)); // สิบสี่นาฬิกาสามสิบนาที
  print(formatClock(t)); // บ่ายสองโมงครึ่ง
  print(formatDuration(const Duration(minutes: 90))); // หนึ่งชั่วโมงสามสิบนาที
}
