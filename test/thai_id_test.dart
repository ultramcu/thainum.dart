// Tests for the Thai National / Tax ID module (A3).
//
// The "valid" sample id used here is SYNTHETIC: its 13th digit was computed by
// the MOD-11 algorithm from the first 12 digits, so it is a structurally valid
// id, NOT a real person's number.

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  // Synthetic valid id (algorithm-derived check digit). Not a real person.
  const validId = '1101700230708';

  group('isValidThaiId', () {
    test('accepts the synthetic valid id', () {
      expect(isValidThaiId(validId), isTrue);
    });

    test('mutation: flipping any single digit invalidates it', () {
      // Position 2 (the third digit) carries MOD-11 weight 11, so changing it
      // alone never alters the checksum (d*11 mod 11 == 0). That is an inherent
      // blind spot of the algorithm, asserted separately below; we skip it here.
      const blindSpot = 2;
      for (var pos = 0; pos < 13; pos++) {
        if (pos == blindSpot) continue;
        for (var alt = 0; alt < 10; alt++) {
          if (alt == validId.codeUnitAt(pos) - 0x30) continue;
          final chars = validId.split('');
          chars[pos] = '$alt';
          final mutated = chars.join();
          expect(isValidThaiId(mutated), isFalse,
              reason: 'mutating pos $pos to $alt should be invalid ($mutated)');
        }
      }
    });

    test('weight-11 blind spot: changing the 3rd digit stays valid', () {
      // Documents the inherent MOD-11 property rather than hiding it.
      for (var alt = 0; alt < 10; alt++) {
        final chars = validId.split('');
        chars[2] = '$alt';
        expect(isValidThaiId(chars.join()), isTrue);
      }
    });

    test('length negatives return false', () {
      expect(isValidThaiId('110170023070'), isFalse); // 12 digits
      expect(isValidThaiId('11017002307088'), isFalse); // 14 digits
      expect(isValidThaiId(''), isFalse);
    });

    test('non-digit characters return false', () {
      expect(isValidThaiId('11017002307AB'), isFalse);
    });

    test('accepts grouped / spaced / Thai-numeral forms', () {
      expect(isValidThaiId('1-1017-00230-70-8'), isTrue);
      expect(isValidThaiId('1 1017 00230 70 8'), isTrue);
      expect(isValidThaiId(toThaiDigits(validId)), isTrue);
    });
  });

  group('isValidThaiTaxId delegates to isValidThaiId', () {
    test('same result', () {
      expect(isValidThaiTaxId(validId), isValidThaiId(validId));
      expect(isValidThaiTaxId('110170023070'), isFalse);
    });
  });

  group('parseThaiId', () {
    test('strips separators and Thai numerals to 13 ASCII digits', () {
      expect(parseThaiId('1-1017-00230-70-8'), validId);
      expect(parseThaiId('1 1017 00230 70 8'), validId);
      expect(parseThaiId(toThaiDigits(validId)), validId);
    });

    test('throws on wrong length or bad characters', () {
      expect(
          () => parseThaiId('110170023070'), throwsA(isA<ThaiNumException>()));
      expect(
          () => parseThaiId('11017002307AB'), throwsA(isA<ThaiNumException>()));
    });
  });

  group('formatThaiId / round-trip', () {
    test('formats to X-XXXX-XXXXX-XX-X', () {
      expect(formatThaiId(validId), '1-1017-00230-70-8');
    });

    test('parseThaiId(formatThaiId(id)) == id', () {
      expect(parseThaiId(formatThaiId(validId)), validId);
    });
  });

  group('classifyThaiId', () {
    test('maps each leading digit to its DOPA category', () {
      const expected = <String, ThaiIdKind>{
        '1': ThaiIdKind.thaiBornRegisteredOnTime,
        '2': ThaiIdKind.thaiBornRegisteredLate,
        '3': ThaiIdKind.thaiInRegistryBefore1984,
        '4': ThaiIdKind.thaiBornBefore1984NotRegistered,
        '5': ThaiIdKind.thaiAddedLater,
        '6': ThaiIdKind.foreignerTemporary,
        '7': ThaiIdKind.childOfForeignerTemporary,
        '8': ThaiIdKind.naturalisedOrPermanentResident,
        '0': ThaiIdKind.unknown,
        '9': ThaiIdKind.unknown,
      };
      expected.forEach((lead, kind) {
        // 13 chars; classification only looks at the leading digit.
        final id = '${lead}000000000000';
        expect(classifyThaiId(id), kind, reason: 'leading $lead');
      });
    });

    test('non-13-digit input is unknown, not a guess', () {
      expect(classifyThaiId('123'), ThaiIdKind.unknown);
    });
  });

  group('speakThaiId', () {
    test('reads digit-by-digit', () {
      expect(
        speakThaiId(validId),
        'หนึ่ง หนึ่ง ศูนย์ หนึ่ง เจ็ด ศูนย์ ศูนย์ สอง สาม ศูนย์ เจ็ด ศูนย์ แปด',
      );
    });

    test('throws when not 13 digits', () {
      expect(() => speakThaiId('123'), throwsA(isA<ThaiNumException>()));
    });
  });

  group('String extensions', () {
    test('forward to the top-level functions', () {
      expect(validId.isValidThaiId(), isTrue);
      expect(validId.isValidThaiTaxId(), isTrue);
      expect(validId.formatThaiId(), '1-1017-00230-70-8');
      expect('1-1017-00230-70-8'.parseThaiId(), validId);
      expect(validId.classifyThaiId(), ThaiIdKind.thaiBornRegisteredOnTime);
      expect(validId.speakThaiId(), speakThaiId(validId));
    });
  });
}
