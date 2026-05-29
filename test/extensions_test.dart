// Tests for the receiver-style extension methods. Each test asserts that
// the extension form returns the same string the equivalent top-level
// function produces — i.e. that the extensions are exact, no-translation
// forwarders. We also check a handful of canonical values so a future
// behavioural change to the underlying primitives doesn't silently slip
// through.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('ThaiIntX', () {
    test('toThaiDigits() matches the top-level fn', () {
      expect(21.toThaiDigits(), '๒๑');
      expect(21.toThaiDigits(), toThaiDigits('21'));
      expect(0.toThaiDigits(), '๐');
      expect((-7).toThaiDigits(), '-๗');
    });

    test('toThousandsString() matches formatInt', () {
      expect(1234567.toThousandsString(), '1,234,567');
      expect(1234567.toThousandsString(), formatInt(1234567));
      expect(0.toThousandsString(), '0');
      expect((-1500).toThousandsString(), '-1,500');
    });

    test('toThaiWords() matches spell()', () {
      expect(21.toThaiWords(), 'ยี่สิบเอ็ด');
      expect(21.toThaiWords(), spell(21));
      expect(101.toThaiWords(), spell(101));
      expect(1000000.toThaiWords(), 'หนึ่งล้าน');
    });

    test('toBahtText() interprets receiver as baht-units', () {
      expect(100.toBahtText(), 'หนึ่งร้อยบาทถ้วน');
      expect(100.toBahtText(), baht(100));
      // Whole-baht, not satang. Sanity check.
      expect(21.toBahtText(), baht(21));
      expect(21.toBahtText(), isNot(bahtSatang(21)));
    });

    test('toThaiOrdinal() / fraction() / toBeYearText()', () {
      expect(21.toThaiOrdinal(), 'ที่ยี่สิบเอ็ด');
      expect(21.toThaiOrdinal(), ordinal(21));
      expect(3.fraction(4), 'เศษสามส่วนสี่');
      expect(3.fraction(4), fraction(3, 4));
      expect(2566.toBeYearText(), 'พุทธศักราชสองพันห้าร้อยหกสิบหก');
      expect(2566.toBeYearText(), year(2566));
    });

    test('CE ↔ BE year conversion', () {
      expect(2026.toBuddhistYear(), 2569);
      expect(2569.toCommonYear(), 2026);
      expect(2026.toBuddhistYear(), ceToBe(2026));
      expect(2569.toCommonYear(), beToCe(2569));
      // Round-trip is identity.
      expect(2026.toBuddhistYear().toCommonYear(), 2026);
    });
  });

  group('ThaiBigIntX', () {
    test('toThaiWords() handles stacked ล้าน', () {
      expect(BigInt.from(10).pow(12).toThaiWords(), 'หนึ่งล้านล้าน');
      expect(
        BigInt.from(10).pow(12).toThaiWords(),
        spellBigInt(BigInt.from(10).pow(12)),
      );
      expect(BigInt.from(10).pow(18).toThaiWords(), 'หนึ่งล้านล้านล้าน');
    });

    test('toBahtText() forwards to the BigInt primitive', () {
      final hundredBaht = BigInt.from(100);
      expect(hundredBaht.toBahtText(), bahtBigInt(hundredBaht));
    });
  });

  group('ThaiDoubleX (lossy)', () {
    test('toBahtText() forwards to bahtFromDouble', () {
      expect(21.21.toBahtText(), bahtFromDouble(21.21));
    });

    test('toSatang() forwards to satangFromFloat (away-from-zero rounding)',
        () {
      expect(21.21.toSatang(), satangFromFloat(21.21));
      expect(0.005.toSatang(), satangFromFloat(0.005));
    });
  });

  group('ThaiStringX', () {
    test('toThaiDigits() / toArabicDigits() round-trip', () {
      expect('101'.toThaiDigits(), '๑๐๑');
      expect('๑๐๑'.toArabicDigits(), '101');
      expect('Year 2566'.toThaiDigits(), 'Year ๒๕๖๖');
      // Round-trip:
      expect('1234567890'.toThaiDigits().toArabicDigits(), '1234567890');
    });

    test('parseThaiInt() / parseThaiBigInt() round-trip', () {
      expect('ยี่สิบเอ็ด'.parseThaiInt(), 21);
      expect('หนึ่งร้อยเอ็ด'.parseThaiInt(), 101);
      expect('หนึ่งร้อยหนึ่ง'.parseThaiInt(), 101); // tensOnly form
      expect('๒๑'.parseThaiInt(), 21);
      expect('หนึ่งล้านล้าน'.parseThaiBigInt(), BigInt.from(10).pow(12));
      // Round-trip with toThaiWords():
      expect(21.toThaiWords().parseThaiInt(), 21);
    });

    test('parseThaiBaht() returns satang amount', () {
      expect(
        'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์'.parseThaiBaht(),
        2121,
      );
    });

    test('parseThaiDate() round-trips toThaiDate()', () {
      final d = DateTime.utc(2024, 6, 5);
      expect(d.toThaiDate().parseThaiDate(), d);
    });

    test('toBahtText() on amount strings (exact, no double)', () {
      expect(
        '21.21'.toBahtText(),
        'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์',
      );
      expect('21.21'.toBahtText(), bahtFromString('21.21'));
    });

    test('toThaiWords() on decimal strings', () {
      expect('12.34'.toThaiWords(), 'สิบสองจุดสามสี่');
      expect('12.34'.toThaiWords(), spellDecimal('12.34'));
    });

    test('parseThaiInt() throws ThaiNumException (a FormatException)', () {
      expect(
        () => 'สิบสิบ'.parseThaiInt(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ThaiDateTimeX', () {
    final d = DateTime.utc(2024, 6, 5); // wednesday

    test('toThaiDate / Abbr / Full forward to the formatters', () {
      expect(d.toThaiDate(), '5 มิถุนายน 2567');
      expect(d.toThaiDate(), formatDate(d));
      expect(d.toThaiDateAbbr(), formatDateAbbr(d));
      expect(d.toThaiDateFull(), formatDateFull(d));
      expect(d.toThaiDateFull(), contains('วันพุธ'));
      expect(d.toThaiDateFull(), contains('พ.ศ. 2567'));
    });

    test('toThaiTime() / toThaiClock() forward to the clock formatters', () {
      final t = DateTime.utc(2024, 1, 1, 14, 30);
      expect(t.toThaiTime(), 'สิบสี่นาฬิกาสามสิบนาที');
      expect(t.toThaiTime(), formatTime(t));
      expect(t.toThaiClock(), 'บ่ายสองโมงครึ่ง');
      expect(t.toThaiClock(), formatClock(t));
    });

    test('buddhistYear / month / weekday getters', () {
      expect(d.buddhistYear, 2567);
      expect(d.thaiMonthName, 'มิถุนายน');
      expect(d.thaiMonthAbbr, monthAbbrTh(6));
      expect(d.thaiWeekdayName, 'วันพุธ');
      expect(d.thaiWeekdayAbbr, weekdayAbbrTh(d));
    });
  });

  group('ThaiDurationX', () {
    test('toThaiText() forwards to formatDuration', () {
      expect(
        const Duration(minutes: 90).toThaiText(),
        'หนึ่งชั่วโมงสามสิบนาที',
      );
      expect(
        const Duration(minutes: 90).toThaiText(),
        formatDuration(const Duration(minutes: 90)),
      );
    });
  });

  // Forwarding-shape sanity check: any future API rename to the underlying
  // top-level functions will be caught by these "extension == function"
  // assertions above. The chained shapes below are exactly the kind of call
  // site the extensions exist for.
  group('chained call shapes', () {
    test('int → toThaiWords() → parseThaiInt() round-trip', () {
      for (final n in [0, 1, 11, 21, 100, 101, 1000, 12345]) {
        expect(
          n.toThaiWords().parseThaiInt(),
          n,
          reason: 'round-trip n=$n',
        );
      }
    });

    test('arabic ↔ thai digit round-trip on a sentence', () {
      const sentence = 'order 42, table 7, due 2024-06-05';
      expect(sentence.toThaiDigits().toArabicDigits(), sentence);
    });

    test('DateTime → toThaiDate() → parseThaiDate() round-trip', () {
      for (final d in [
        DateTime.utc(2024, 1, 1),
        DateTime.utc(2024, 6, 5),
        DateTime.utc(2026, 5, 29),
        DateTime.utc(1999, 12, 31),
      ]) {
        expect(
          d.toThaiDate().parseThaiDate(),
          d,
          reason: 'round-trip d=$d',
        );
      }
    });
  });
}
