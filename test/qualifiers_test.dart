import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('approx', () {
    test('examples', () {
      expect(thaiApprox(100), 'ประมาณหนึ่งร้อย');
      expect(thaiApprox(21), 'ประมาณยี่สิบเอ็ด');
      expect(thaiApprox(0), 'ประมาณศูนย์');
      expect(thaiApprox(-5), 'ประมาณลบห้า');
    });
    test('extension', () {
      expect(100.toThaiApprox(), 'ประมาณหนึ่งร้อย');
      expect(100.toThaiQualified(QualifierKind.approx), 'ประมาณหนึ่งร้อย');
    });
  });

  group('nearly', () {
    test('examples', () {
      expect(thaiNearly(100), 'เกือบหนึ่งร้อย');
      expect(thaiNearly(20), 'เกือบยี่สิบ');
      expect(thaiNearly(-5), 'เกือบลบห้า');
    });
    test('extension', () {
      expect(100.toThaiNearly(), 'เกือบหนึ่งร้อย');
      expect(20.toThaiQualified(QualifierKind.nearly), 'เกือบยี่สิบ');
    });
  });

  group('range', () {
    test('examples', () {
      expect(thaiRange(10, 20), 'สิบถึงยี่สิบ');
      expect(thaiRange(1, 5), 'หนึ่งถึงห้า');
      expect(thaiRange(-5, 5), 'ลบห้าถึงห้า');
    });
    test('no ordering imposed', () {
      expect(thaiRange(20, 10), 'ยี่สิบถึงสิบ');
      expect(thaiRange(5, 5), 'ห้าถึงห้า');
    });
    test('extension', () {
      expect(10.toThaiRange(20), 'สิบถึงยี่สิบ');
    });
  });

  group('moreThan (กว่า) — round-magnitude domain', () {
    test('valid round magnitudes', () {
      expect(thaiMoreThan(10), 'สิบกว่า');
      expect(thaiMoreThan(20), 'ยี่สิบกว่า');
      expect(thaiMoreThan(90), 'เก้าสิบกว่า');
      expect(thaiMoreThan(100), 'หนึ่งร้อยกว่า');
      expect(thaiMoreThan(500), 'ห้าร้อยกว่า');
      expect(thaiMoreThan(1000), 'หนึ่งพันกว่า');
      expect(thaiMoreThan(10000), 'หนึ่งหมื่นกว่า');
      expect(thaiMoreThan(100000), 'หนึ่งแสนกว่า');
      expect(thaiMoreThan(1000000), 'หนึ่งล้านกว่า');
      expect(thaiMoreThan(3000000), 'สามล้านกว่า');
    });

    test('extension', () {
      expect(10.toThaiMoreThan(), 'สิบกว่า');
      expect(20.toThaiQualified(QualifierKind.moreThan), 'ยี่สิบกว่า');
    });

    test('non-round numbers throw notRoundMagnitude', () {
      for (final bad in [11, 15, 19, 21, 150, 999, 1234]) {
        final e = _catch(() => thaiMoreThan(bad));
        expect(e, isA<ThaiNumException>());
        expect(e!.code, ThaiNumError.notRoundMagnitude);
      }
    });

    test('single digit / zero / negative throw', () {
      for (final bad in [0, 1, 5, 9, -10, -100]) {
        final e = _catch(() => thaiMoreThan(bad));
        expect(e, isA<ThaiNumException>());
        expect(e!.code, ThaiNumError.notRoundMagnitude);
      }
    });

    test('extension on non-round throws', () {
      expect(() => 11.toThaiMoreThan(), throwsA(isA<ThaiNumException>()));
    });
  });

  group('isRoundMagnitude', () {
    test('round', () {
      for (final n in [10, 20, 90, 100, 500, 1000, 1000000, 7000000]) {
        expect(isRoundMagnitude(n), isTrue, reason: '$n');
      }
    });
    test('not round', () {
      for (final n in [0, 1, 9, 11, 15, 99, 101, 150, 1234, -10]) {
        expect(isRoundMagnitude(n), isFalse, reason: '$n');
      }
    });
  });

  test('notRoundMagnitude has a Thai message', () {
    final e = _catch(() => thaiMoreThan(11));
    expect(e!.messageTh, contains('กว่า'));
  });
}

ThaiNumException? _catch(void Function() f) {
  try {
    f();
    return null;
  } on ThaiNumException catch (e) {
    return e;
  }
}
