// A tiny command-line front-end for `package:thainum`.
//
// It is a thin layer over the public library API and adds NO dependency: the
// argument parsing below is hand-rolled on purpose so the package graph stays
// dependency-free (no `package:args`). `runCli` returns the captured output and
// an exit code so it can be driven directly from a fast, deterministic test;
// `main` just forwards to it and prints.
import 'dart:io';

import 'package:thainum/thainum.dart';

/// The result of one CLI invocation: the text to print and the process exit
/// code (`0` on success, non-zero on error).
class CliResult {
  /// Creates a result with [output] (without a trailing newline) and
  /// [exitCode].
  CliResult(this.output, this.exitCode);

  /// What the command would print to stdout/stderr (no trailing newline).
  final String output;

  /// The process exit code: `0` on success, non-zero on error.
  final int exitCode;
}

const String _usage = '''
thainum — Thai number toolkit CLI

Usage: thainum <command> [args] [flags]

Commands:
  spell <int>            Spell an integer in Thai words.
  baht <amount>          Render an amount (int or decimal string) as baht text.
  parse <thai-words>     Parse Thai number words back into a number.
  digits <int>           Convert ASCII digits to Thai numerals.
  date <YYYY-MM-DD>      Format a date as a Thai (Buddhist-Era) date.

Flags:
  --et=always|tensOnly   Trailing-one convention for `spell` (default always).
  --full                 `date`: full form (weekday + พ.ศ.).
  --abbr                 `date`: abbreviated month form.
  --json                 Emit a small JSON object instead of bare text.
  --help, -h             Show this help.

Examples:
  thainum spell 101
  thainum spell 101 --et=tensOnly
  thainum baht 21.21
  thainum parse ยี่สิบเอ็ด --json
  thainum digits 2566
  thainum date 2024-06-05 --full''';

/// Runs the CLI for [args] and returns the captured output + exit code without
/// touching the process — so tests can call it directly.
CliResult runCli(List<String> args) {
  // ---- hand-rolled flag split: pull `--flag` / `--flag=value` out, keep the
  // rest as positional arguments. No package:args.
  final positional = <String>[];
  final flags = <String, String>{};
  for (final a in args) {
    if (a == '--help' || a == '-h') {
      flags['help'] = '';
    } else if (a.startsWith('--')) {
      final body = a.substring(2);
      final eq = body.indexOf('=');
      if (eq >= 0) {
        flags[body.substring(0, eq)] = body.substring(eq + 1);
      } else {
        flags[body] = '';
      }
    } else {
      positional.add(a);
    }
  }

  if (flags.containsKey('help') || positional.isEmpty) {
    return CliResult(_usage, flags.containsKey('help') ? 0 : 64);
  }

  final cmd = positional.first;
  final rest = positional.sublist(1);
  final wantJson = flags.containsKey('json');

  try {
    final (label, value) = _dispatch(cmd, rest, flags);
    return CliResult(_format(label, value, wantJson), 0);
  } on ThaiNumException catch (e) {
    return CliResult(_error(e.message, wantJson), 1);
  } on _CliError catch (e) {
    return CliResult(_error(e.message, wantJson), e.exitCode);
  } on FormatException catch (e) {
    return CliResult(_error(e.message, wantJson), 1);
  }
}

/// A `(label, value)` pair: `label` is the JSON field name for `--json`.
(String, String) _dispatch(
    String cmd, List<String> rest, Map<String, String> flags) {
  switch (cmd) {
    case 'spell':
      final n = _requireInt(rest, 'spell <int>');
      final et = _etMode(flags);
      return ('words', Speller(et: et).spellInt(n));
    case 'baht':
      final amount = _requireOne(rest, 'baht <amount>');
      // A bare integer is whole baht; anything with a '.' is a decimal string.
      final text = amount.contains('.')
          ? bahtFromString(amount)
          : baht(int.parse(amount));
      return ('bahtText', text);
    case 'parse':
      final words = _requireOne(rest, 'parse <thai-words>');
      // `lenient` so multiple shell tokens joined with spaces (e.g.
      // `parse ยี่สิบ เอ็ด`) parse as one number.
      return ('value', parseDecimal(words, lenient: true));
    case 'digits':
      final raw = _requireOne(rest, 'digits <int>');
      return ('thaiDigits', toThaiDigits(raw));
    case 'date':
      final d = _parseIsoDate(_requireOne(rest, 'date <YYYY-MM-DD>'));
      if (flags.containsKey('full')) return ('date', formatDateFull(d));
      if (flags.containsKey('abbr')) return ('date', formatDateAbbr(d));
      return ('date', formatDate(d));
    default:
      throw _CliError('unknown command: $cmd\n\n$_usage', 64);
  }
}

EtMode _etMode(Map<String, String> flags) {
  final v = flags['et'];
  switch (v) {
    case null:
    case '':
    case 'always':
      return EtMode.always;
    case 'tensOnly':
      return EtMode.tensOnly;
    default:
      throw _CliError('--et must be "always" or "tensOnly" (got "$v")', 64);
  }
}

String _requireOne(List<String> rest, String form) {
  if (rest.isEmpty) throw _CliError('missing argument: $form', 64);
  return rest.join(' ');
}

int _requireInt(List<String> rest, String form) {
  final s = _requireOne(rest, form);
  final n = int.tryParse(s.replaceAll(',', ''));
  if (n == null) throw _CliError('expected an integer, got "$s"', 64);
  return n;
}

DateTime _parseIsoDate(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
  if (m == null) {
    throw _CliError('expected a date as YYYY-MM-DD, got "$s"', 64);
  }
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final dy = int.parse(m.group(3)!);
  final d = DateTime(y, mo, dy);
  if (d.year != y || d.month != mo || d.day != dy) {
    throw _CliError('not a valid calendar date: "$s"', 64);
  }
  return d;
}

String _format(String label, String value, bool json) {
  if (!json) return value;
  return '{"$label": ${_jsonString(value)}}';
}

String _error(String message, bool json) {
  if (!json) return 'error: $message';
  return '{"error": ${_jsonString(message)}}';
}

/// Encodes [s] as a JSON string literal (handles the characters that can occur
/// in our outputs/messages); avoids pulling in `dart:convert` just for this.
String _jsonString(String s) {
  final buf = StringBuffer('"');
  for (final unit in s.codeUnits) {
    switch (unit) {
      case 0x22:
        buf.write(r'\"');
      case 0x5C:
        buf.write(r'\\');
      case 0x08:
        buf.write(r'\b');
      case 0x09:
        buf.write(r'\t');
      case 0x0A:
        buf.write(r'\n');
      case 0x0C:
        buf.write(r'\f');
      case 0x0D:
        buf.write(r'\r');
      default:
        if (unit < 0x20) {
          buf.write('\\u${unit.toRadixString(16).padLeft(4, '0')}');
        } else {
          buf.writeCharCode(unit);
        }
    }
  }
  buf.write('"');
  return buf.toString();
}

/// An internal CLI usage/argument error carrying its own exit code.
class _CliError implements Exception {
  _CliError(this.message, this.exitCode);
  final String message;
  final int exitCode;
}

/// CLI entry point: parse, run, print, and set the process exit code.
void main(List<String> args) {
  final r = runCli(args);
  if (r.exitCode == 0) {
    stdout.writeln(r.output);
  } else {
    stderr.writeln(r.output);
  }
  exitCode = r.exitCode;
}
