// Tests for the hand-rolled CLI (B1). Drives `runCli` directly (fast,
// deterministic) instead of spawning a subprocess.

import 'package:test/test.dart';

import '../bin/thainum.dart';

void main() {
  group('spell', () {
    test('spells an integer', () {
      final r = runCli(['spell', '101']);
      expect(r.exitCode, 0);
      expect(r.output, 'หนึ่งร้อยเอ็ด');
    });

    test('--et=tensOnly changes the trailing-one reading', () {
      expect(runCli(['spell', '101']).output, 'หนึ่งร้อยเอ็ด');
      expect(
          runCli(['spell', '101', '--et=tensOnly']).output, 'หนึ่งร้อยหนึ่ง');
    });

    test('rejects a bad --et value', () {
      final r = runCli(['spell', '1', '--et=nope']);
      expect(r.exitCode, isNot(0));
      expect(r.output, contains('--et'));
    });

    test('accepts a comma-grouped integer', () {
      expect(runCli(['spell', '1,000']).output, 'หนึ่งพัน');
    });
  });

  group('baht', () {
    test('whole baht', () {
      expect(runCli(['baht', '100']).output, 'หนึ่งร้อยบาทถ้วน');
    });

    test('decimal string', () {
      expect(runCli(['baht', '21.21']).output, 'ยี่สิบเอ็ดบาทยี่สิบเอ็ดสตางค์');
    });
  });

  group('parse', () {
    test('parses Thai words back to a number', () {
      expect(runCli(['parse', 'ยี่สิบเอ็ด']).output, '21');
    });

    test('joins multiple positional tokens', () {
      expect(runCli(['parse', 'ยี่สิบ', 'เอ็ด']).output, '21');
    });

    test('decimal words', () {
      expect(runCli(['parse', 'สิบสองจุดสามสี่']).output, '12.34');
    });
  });

  group('digits', () {
    test('converts to Thai numerals', () {
      expect(runCli(['digits', '2566']).output, '๒๕๖๖');
    });
  });

  group('date', () {
    test('short form', () {
      expect(runCli(['date', '2024-06-05']).output, '5 มิถุนายน 2567');
    });

    test('--abbr', () {
      expect(runCli(['date', '2024-06-05', '--abbr']).output, '5 มิ.ย. 2567');
    });

    test('--full', () {
      expect(runCli(['date', '2024-06-05', '--full']).output,
          'วันพุธที่ 5 มิถุนายน พ.ศ. 2567');
    });

    test('rejects a malformed date', () {
      final r = runCli(['date', 'not-a-date']);
      expect(r.exitCode, isNot(0));
    });
  });

  group('--json', () {
    test('emits a JSON object', () {
      final r = runCli(['spell', '101', '--json']);
      expect(r.exitCode, 0);
      expect(r.output, '{"words": "หนึ่งร้อยเอ็ด"}');
    });

    test('errors are JSON too', () {
      final r = runCli(['baht', 'xyz', '--json']);
      expect(r.exitCode, isNot(0));
      expect(r.output, startsWith('{"error":'));
    });
  });

  group('help & errors', () {
    test('--help exits 0 and prints usage', () {
      final r = runCli(['--help']);
      expect(r.exitCode, 0);
      expect(r.output, contains('Usage:'));
    });

    test('no args prints usage with a non-zero exit', () {
      final r = runCli([]);
      expect(r.exitCode, isNot(0));
      expect(r.output, contains('Usage:'));
    });

    test('unknown command is an error', () {
      final r = runCli(['frobnicate']);
      expect(r.exitCode, isNot(0));
      expect(r.output, contains('unknown command'));
    });

    test('catches ThaiNumException with a clean message', () {
      final r = runCli(['parse', 'ไม่ใช่เลข']);
      expect(r.exitCode, 1);
      expect(r.output, startsWith('error:'));
    });
  });
}
