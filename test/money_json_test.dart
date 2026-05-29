// Tests for the value-type completeness + JSON surface on the money wrappers
// (B4): Comparable, copyWith, toJson/fromJson, and the JsonConverter-shaped
// adapter classes. The existing ==/hashCode/toString contract is re-checked to
// confirm it is unchanged.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:thainum/thainum.dart';

void main() {
  group('Comparable', () {
    test('Satang.compareTo orders by value', () {
      expect(const Satang(100).compareTo(const Satang(200)), lessThan(0));
      expect(const Satang(200).compareTo(const Satang(100)), greaterThan(0));
      expect(const Satang(100).compareTo(const Satang(100)), 0);
    });

    test('Baht.compareTo orders by value', () {
      expect(const Baht(1).compareTo(const Baht(2)), lessThan(0));
      expect(const Baht(2).compareTo(const Baht(2)), 0);
    });

    test('BigInt wrappers order by value', () {
      expect(
        BahtBigInt(BigInt.from(5)).compareTo(BahtBigInt(BigInt.from(9))),
        lessThan(0),
      );
      expect(
        SatangBigInt(BigInt.from(9)).compareTo(SatangBigInt(BigInt.from(5))),
        greaterThan(0),
      );
    });

    test('a list of Satang sorts ascending', () {
      final list = [
        const Satang(300),
        const Satang(-50),
        const Satang(100),
        const Satang(0),
      ]..sort();
      expect(list.map((s) => s.value), [-50, 0, 100, 300]);
    });

    test('a list of BahtBigInt sorts ascending', () {
      final list = [
        BahtBigInt(BigInt.parse('1000000000000000000000')),
        BahtBigInt(BigInt.from(-7)),
        BahtBigInt(BigInt.zero),
      ]..sort();
      expect(
        list.map((b) => b.value.toString()),
        ['-7', '0', '1000000000000000000000'],
      );
    });
  });

  group('copyWith', () {
    test('Baht.copyWith replaces value; empty copyWith is equal', () {
      expect(const Baht(100).copyWith(value: 200), const Baht(200));
      expect(const Baht(100).copyWith(), const Baht(100));
    });

    test('Satang.copyWith replaces value', () {
      expect(const Satang(2121).copyWith(value: 0), const Satang(0));
      expect(const Satang(2121).copyWith(), const Satang(2121));
    });

    test('BigInt wrappers copyWith', () {
      expect(
        BahtBigInt(BigInt.from(5)).copyWith(value: BigInt.from(6)),
        BahtBigInt(BigInt.from(6)),
      );
      expect(
        SatangBigInt(BigInt.from(5)).copyWith(),
        SatangBigInt(BigInt.from(5)),
      );
    });
  });

  group('toJson / fromJson round-trip', () {
    test('Baht wire form is an int', () {
      expect(const Baht(100).toJson(), 100);
      expect(const Baht(100).toJson(), isA<int>());
      expect(Baht.fromJson(const Baht(100).toJson()), const Baht(100));
      expect(Baht.fromJson(const Baht(-5).toJson()), const Baht(-5));
    });

    test('Satang wire form is an int', () {
      expect(const Satang(2121).toJson(), 2121);
      expect(const Satang(2121).toJson(), isA<int>());
      expect(
        Satang.fromJson(const Satang(2121).toJson()),
        const Satang(2121),
      );
    });

    test('BahtBigInt wire form is a decimal String', () {
      final big = BahtBigInt(BigInt.parse('123456789012345678901234567890'));
      expect(big.toJson(), '123456789012345678901234567890');
      expect(big.toJson(), isA<String>());
      expect(BahtBigInt.fromJson(big.toJson()), big);
      expect(
        BahtBigInt.fromJson(BahtBigInt(BigInt.from(-9)).toJson()),
        BahtBigInt(BigInt.from(-9)),
      );
    });

    test('SatangBigInt wire form is a decimal String', () {
      final big = SatangBigInt(BigInt.parse('-999999999999999999999'));
      expect(big.toJson(), '-999999999999999999999');
      expect(big.toJson(), isA<String>());
      expect(SatangBigInt.fromJson(big.toJson()), big);
    });

    test('survives a real jsonEncode/jsonDecode pass', () {
      final payload = {
        'baht': const Baht(100).toJson(),
        'satang': const Satang(2121).toJson(),
        'bigBaht': BahtBigInt(BigInt.parse('10000000000000000000')).toJson(),
        'bigSatang':
            SatangBigInt(BigInt.parse('20000000000000000001')).toJson(),
      };
      final decoded = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
      expect(Baht.fromJson(decoded['baht']), const Baht(100));
      expect(Satang.fromJson(decoded['satang']), const Satang(2121));
      expect(
        BahtBigInt.fromJson(decoded['bigBaht']),
        BahtBigInt(BigInt.parse('10000000000000000000')),
      );
      expect(
        SatangBigInt.fromJson(decoded['bigSatang']),
        SatangBigInt(BigInt.parse('20000000000000000001')),
      );
    });

    test('int wrappers accept an integer-valued JSON number (21.0)', () {
      // jsonDecode may yield a double for a number written without a fraction.
      expect(Satang.fromJson(21.0), const Satang(21));
      expect(Baht.fromJson(100.0), const Baht(100));
    });

    test('BigInt wrappers accept a bare int for convenience', () {
      expect(BahtBigInt.fromJson(5), BahtBigInt(BigInt.from(5)));
      expect(SatangBigInt.fromJson(-7), SatangBigInt(BigInt.from(-7)));
    });
  });

  group('fromJson throws on bad shape', () {
    test('int wrappers reject a fractional number', () {
      expect(() => Satang.fromJson(2.5), throwsA(isA<ThaiNumException>()));
      expect(() => Baht.fromJson(1.1), throwsA(isA<FormatException>()));
    });

    test('int wrappers reject a String', () {
      expect(() => Satang.fromJson('100'), throwsA(isA<ThaiNumException>()));
    });

    test('int wrappers reject null / wrong type', () {
      expect(() => Baht.fromJson(null), throwsA(isA<ThaiNumException>()));
      expect(() => Baht.fromJson(true), throwsA(isA<ThaiNumException>()));
      expect(() => Satang.fromJson([1]), throwsA(isA<ThaiNumException>()));
    });

    test('BigInt wrappers reject a malformed string', () {
      expect(
        () => BahtBigInt.fromJson('not-a-number'),
        throwsA(isA<ThaiNumException>()),
      );
      expect(
        () => SatangBigInt.fromJson('12.5'),
        throwsA(isA<ThaiNumException>()),
      );
    });

    test('BigInt wrappers reject a double / null', () {
      expect(
        () => BahtBigInt.fromJson(1.5),
        throwsA(isA<ThaiNumException>()),
      );
      expect(
        () => SatangBigInt.fromJson(null),
        throwsA(isA<ThaiNumException>()),
      );
    });

    test('thrown exception carries the invalidNumber code', () {
      try {
        Satang.fromJson('nope');
        fail('expected throw');
      } on ThaiNumException catch (e) {
        expect(e.code, ThaiNumError.invalidNumber);
      }
    });
  });

  group('JsonConverter-shaped adapter classes round-trip', () {
    test('SatangConverter', () {
      const c = SatangConverter();
      expect(c.toJson(const Satang(2121)), 2121);
      expect(c.fromJson(2121), const Satang(2121));
      expect(c.fromJson(c.toJson(const Satang(7))), const Satang(7));
    });

    test('BahtConverter', () {
      const c = BahtConverter();
      expect(c.toJson(const Baht(100)), 100);
      expect(c.fromJson(100), const Baht(100));
    });

    test('BahtBigIntConverter', () {
      const c = BahtBigIntConverter();
      final v = BahtBigInt(BigInt.parse('99999999999999999999'));
      expect(c.toJson(v), '99999999999999999999');
      expect(c.fromJson(c.toJson(v)), v);
    });

    test('SatangBigIntConverter', () {
      const c = SatangBigIntConverter();
      final v = SatangBigInt(BigInt.from(42));
      expect(c.toJson(v), '42');
      expect(c.fromJson(c.toJson(v)), v);
    });

    test('converters are const-constructible', () {
      const a = SatangConverter();
      const b = SatangConverter();
      expect(identical(a, b), isTrue);
    });
  });

  group('existing ==/hashCode/toString contract is unchanged', () {
    test('Satang value-equality + works as a Map key', () {
      expect(const Satang(2121), const Satang(2121));
      expect(const Satang(2121).hashCode, const Satang(2121).hashCode);
      final m = {const Satang(2121): 'a'};
      expect(m[const Satang(2121)], 'a');
    });

    test('Set membership by value', () {
      final s = <Baht>{}
        ..add(const Baht(1))
        ..add(const Baht(1))
        ..add(const Baht(2));
      expect(s, hasLength(2));
    });

    test('toString is unchanged', () {
      expect(const Baht(100).toString(), 'Baht(100)');
      expect(const Satang(2121).toString(), 'Satang(2121)');
      expect(BahtBigInt(BigInt.from(5)).toString(), 'BahtBigInt(5)');
      expect(SatangBigInt(BigInt.from(9)).toString(), 'SatangBigInt(9)');
    });

    test('different types with same int are not equal', () {
      // (Baht and Satang are distinct types; this guards the `is` check.)
      final Object baht = const Baht(21);
      expect(baht == const Satang(21), isFalse);
    });
  });
}
