// B6: structured error codes + Thai messages + precise offsets.
//
// Each malformed input must produce the right [ThaiNumError] code, a non-empty
// Thai [messageTh], while keeping the English [message] and [toString()]
// byte-identical to the pre-B6 behaviour (these strings are locked in below).

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

/// Captures the [ThaiNumException] thrown by [body], failing the test if none
/// is thrown.
ThaiNumException _catch(void Function() body) {
  try {
    body();
  } on ThaiNumException catch (e) {
    return e;
  }
  fail('expected a ThaiNumException');
}

void main() {
  group('ThaiNumError code is set per failure', () {
    final cases = <String, ({void Function() run, ThaiNumError code})>{
      'empty input': (run: () => parseInt(''), code: ThaiNumError.emptyInput),
      'unknown token': (
        run: () => parseInt('กขค'),
        code: ThaiNumError.unknownToken,
      ),
      'two digits in a row': (
        run: () => parseInt('สองสาม'),
        code: ThaiNumError.twoDigitsInARow,
      ),
      'misplaced place word (repeat)': (
        run: () => parseInt('สิบสิบ'),
        code: ThaiNumError.misplacedPlaceWord,
      ),
      'misplaced place word (ascending)': (
        run: () => parseInt('ร้อยพัน'),
        code: ThaiNumError.misplacedPlaceWord,
      ),
      'misplaced word (zero in compound)': (
        run: () => parseInt('ศูนย์สิบ'),
        code: ThaiNumError.misplacedWord,
      ),
      'เอ็ด cannot precede place': (
        run: () => parseInt('เอ็ดสิบ'),
        code: ThaiNumError.etCannotPrecedePlace,
      ),
      'ยี่ must precede สิบ': (
        run: () => parseInt('ยี่ร้อย'),
        code: ThaiNumError.yiMustPrecedeSib,
      ),
      'ยี่ trailing (no place)': (
        run: () => parseInt('ยี่'),
        code: ThaiNumError.yiMustPrecedeSib,
      ),
      'ล้าน groups out of order': (
        run: () => parseInt('ล้านห้าล้าน'),
        code: ThaiNumError.millionGroupsOutOfOrder,
      ),
      'ลบ alone': (
        run: () => parseInt('ลบ'),
        code: ThaiNumError.negAloneNotNumber,
      ),
      'satang out of range': (
        run: () => parseBaht('สองบาทร้อยสตางค์'),
        code: ThaiNumError.satangOutOfRange,
      ),
      'multiple จุด': (
        run: () => parseDecimal('หนึ่งจุดสองจุดสาม'),
        code: ThaiNumError.multipleDecimalPoints,
      ),
      'missing fractional part': (
        run: () => parseDecimal('หนึ่งจุด'),
        code: ThaiNumError.missingFractionalPart,
      ),
      'missing integer part': (
        run: () => parseDecimal('จุดห้า'),
        code: ThaiNumError.missingIntegerPart,
      ),
      'invalid fractional digit word': (
        run: () => parseDecimal('หนึ่งจุดสิบ'),
        code: ThaiNumError.unknownToken,
      ),
      'overflows int': (
        run: () => parseInt('สิบล้านล้านล้าน'), // 10^19 > maxInt
        code: ThaiNumError.overflowsInt,
      ),
      'spellDecimal invalid number': (
        run: () => spellDecimal('12.3.4'),
        code: ThaiNumError.invalidNumber,
      ),
      'date: no month': (
        run: () => parseDate('ไม่ใช่วันที่'),
        code: ThaiNumError.noMonthFound,
      ),
      'date: missing day/year': (
        run: () => parseDate('มิถุนายน'),
        code: ThaiNumError.missingDayOrYear,
      ),
      'date: invalid date': (
        run: () => parseDate('99 มกราคม 2567'),
        code: ThaiNumError.invalidDate,
      ),
      'thai id: bad char': (
        run: () => parseThaiId('11017002307AB'),
        code: ThaiNumError.invalidThaiIdChar,
      ),
      'thai id: wrong length': (
        run: () => parseThaiId('110170023070'),
        code: ThaiNumError.thaiIdWrongLength,
      ),
    };

    cases.forEach((name, c) {
      test('$name -> ${c.code}', () {
        final e = _catch(c.run);
        expect(e.code, c.code);
        // messageTh is non-empty and contains Thai characters.
        expect(e.messageTh, isNotEmpty);
        expect(e.messageTh, isNot(equals(e.message)),
            reason: 'Thai message should differ from English');
        expect(RegExp(r'[฀-๿]').hasMatch(e.messageTh), isTrue,
            reason: 'messageTh should contain Thai characters');
      });
    });

    test('every ThaiNumError value has a non-empty Thai message', () {
      // Build a fake exception per code to confirm the lookup table is total.
      for (final code in ThaiNumError.values) {
        final e = ThaiNumException('x', null, null, code);
        expect(e.messageTh, isNotEmpty, reason: 'no Thai message for $code');
        expect(RegExp(r'[฀-๿]').hasMatch(e.messageTh), isTrue);
      }
    });
  });

  group('message / toString stay byte-identical (backward compat)', () {
    test('two digits in a row', () {
      // The offending (second) token is reported as the source, unchanged.
      final e = _catch(() => parseInt('สองสาม'));
      expect(e.message, 'thainum: two digits in a row');
      expect(e.toString(),
          'ThaiNumException: thainum: two digits in a row ("สาม")');
    });

    test('misplaced place word', () {
      final e = _catch(() => parseInt('สิบสิบ'));
      expect(e.message, 'thainum: misplaced place word');
      expect(e.toString(),
          'ThaiNumException: thainum: misplaced place word ("สิบ")');
    });

    test('empty input has no source in toString', () {
      final e = _catch(() => parseInt(''));
      expect(e.message, 'thainum: empty input');
      expect(e.toString(), 'ThaiNumException: thainum: empty input');
    });

    test('unknown token', () {
      final e = _catch(() => parseInt('กขค'));
      expect(e.message, 'thainum: unknown token');
      expect(e.toString(), 'ThaiNumException: thainum: unknown token ("กขค")');
    });

    test('satang out of range message + source unchanged', () {
      final e = _catch(() => parseBaht('สองบาทร้อยสตางค์'));
      expect(e.message, 'thainum: satang 100 out of range 0..99');
      expect(e.toString(),
          'ThaiNumException: thainum: satang 100 out of range 0..99 ("สองบาทร้อยสตางค์")');
    });

    test('null code yields messageTh == message (fallback)', () {
      const e = ThaiNumException('thainum: anything');
      expect(e.code, isNull);
      expect(e.messageTh, 'thainum: anything');
    });
  });

  group('precise offset into digit-normalized input', () {
    test('two digits in a row points at the second digit', () {
      // สอง = 3 chars, สาม starts at index 3.
      final e = _catch(() => parseInt('สองสาม'));
      expect(e.offset, 'สอง'.length);
    });

    test('misplaced place word points at the offending place', () {
      // สิบ (3) then second สิบ at index 3.
      final e = _catch(() => parseInt('สิบสิบ'));
      expect(e.offset, 'สิบ'.length);
    });

    test('offset accounts for a leading ลบ', () {
      // ลบ (2) + สอง (3) -> second digit at index 5.
      final e = _catch(() => parseInt('ลบสองสาม'));
      expect(e.offset, 'ลบสอง'.length);
    });

    test('parseBaht satang-part error offset is relative to full input', () {
      // 'หนึ่งบาท' + 'สิบสิบ' + 'สตางค์': the bad second สิบ in the satang part
      // must be reported at its position in the whole string, not within the
      // satang substring (the latent substring-offset bug).
      const input = 'หนึ่งบาทสิบสิบสตางค์';
      final e = _catch(() => parseBaht(input));
      expect(e.code, ThaiNumError.misplacedPlaceWord);
      final expectedOffset = 'หนึ่งบาทสิบ'.length;
      expect(e.offset, expectedOffset);
      // The reported offset really points at the second สิบ.
      expect(input.substring(e.offset!).startsWith('สิบ'), isTrue);
    });

    test('lenient path leaves offsets null (cannot be computed)', () {
      final e = _catch(() => parseInt('สอง สาม', lenient: true));
      expect(e.code, ThaiNumError.twoDigitsInARow);
      expect(e.offset, isNull);
    });

    test('describe() renders a caret under the bad token', () {
      final e = _catch(() => parseInt('สองสาม'));
      final out = e.describe();
      expect(out, contains('\n'));
      // The caret line has `offset` spaces then '^'.
      final lines = out.split('\n');
      expect(lines.last, '${' ' * e.offset!}^');
    });

    test('describe() falls back to message with no offset', () {
      final e = _catch(() => parseInt(''));
      expect(e.describe(), e.message);
    });
  });
}
