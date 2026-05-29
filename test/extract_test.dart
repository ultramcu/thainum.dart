// Tests for extractNumbers (A1). Asserts values, offsets, and the documented
// maximal-munch boundary rule for word runs.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('extractNumbers', () {
    test('mixed digits and words in a sentence', () {
      const text = 'ซื้อมา ๓ ชิ้น ราคาห้าร้อยบาท';
      final ms = extractNumbers(text);
      expect(ms.length, 2);

      expect(ms[0].value, BigInt.from(3));
      expect(ms[0].isDigits, isTrue);
      expect(ms[0].isWord, isFalse);
      expect(ms[0].matched, '๓');
      expect(text.substring(ms[0].start, ms[0].end), '๓');

      expect(ms[1].value, BigInt.from(500));
      expect(ms[1].isWord, isTrue);
      expect(ms[1].isDigits, isFalse);
      expect(ms[1].matched, 'ห้าร้อย');
      expect(text.substring(ms[1].start, ms[1].end), 'ห้าร้อย');
    });

    test('a compound word is ONE match, not two', () {
      final ms = extractNumbers('ยี่สิบเอ็ด');
      expect(ms.length, 1);
      expect(ms.single.value, BigInt.from(21));
      expect(ms.single.matched, 'ยี่สิบเอ็ด');
    });

    test('Arabic and Thai digit groups', () {
      const text = 'เลข 101 และ ๒๐๒';
      final ms = extractNumbers(text);
      expect(ms.map((m) => m.value).toList(),
          [BigInt.from(101), BigInt.from(202)]);
      expect(ms.every((m) => m.isDigits), isTrue);
      for (final m in ms) {
        expect(text.substring(m.start, m.end), m.matched);
      }
    });

    test('no numbers → empty list', () {
      expect(extractNumbers('ไม่มีเลข'), isEmpty);
      expect(extractNumbers(''), isEmpty);
    });

    test('maximal-munch: longest valid prefix then resume', () {
      // 'ห้าร้อยสิบสิบ' → 'ห้าร้อยสิบ' (510) + 'สิบ' (10): the second สิบ
      // makes the run invalid (repeated place), so the longest valid prefix is
      // emitted and scanning resumes after it.
      final ms = extractNumbers('ห้าร้อยสิบสิบ');
      expect(ms.length, 2);
      expect(ms[0].value, BigInt.from(510));
      expect(ms[0].matched, 'ห้าร้อยสิบ');
      expect(ms[1].value, BigInt.from(10));
      expect(ms[1].matched, 'สิบ');
    });

    test('offsets are correct into the original text', () {
      const text = 'a สิบ b 7 c';
      final ms = extractNumbers(text);
      for (final m in ms) {
        expect(text.substring(m.start, m.end), m.matched);
      }
      expect(
          ms.map((m) => m.value).toList(), [BigInt.from(10), BigInt.from(7)]);
    });

    test('ลบ is a connector, not part of a match (magnitudes only)', () {
      final ms = extractNumbers('ลบห้า');
      expect(ms.length, 1);
      expect(ms.single.value, BigInt.from(5));
      expect(ms.single.matched, 'ห้า');
    });
  });
}
