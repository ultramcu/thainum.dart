import 'exception.dart';
import 'numerals.dart';

/// Full Thai month names, 1-indexed (`thaiMonths[1] == "มกราคม"`). Index 0 is
/// an empty placeholder.
const List<String> _thaiMonths = [
  '',
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

/// Abbreviated Thai month names, 1-indexed.
const List<String> _thaiMonthsAbbr = [
  '',
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

/// Full Thai weekday names, indexed Sunday=0 .. Saturday=6 (Go's order).
const List<String> _thaiWeekdays = [
  'อาทิตย์',
  'จันทร์',
  'อังคาร',
  'พุธ',
  'พฤหัสบดี',
  'ศุกร์',
  'เสาร์',
];

/// Abbreviated Thai weekday names, indexed Sunday=0 .. Saturday=6.
const List<String> _thaiWeekdaysAbbr = [
  'อา.',
  'จ.',
  'อ.',
  'พ.',
  'พฤ.',
  'ศ.',
  'ส.',
];

/// Converts a [DateTime.weekday] (Monday=1 .. Sunday=7) to the Sunday=0 index
/// used by the Thai weekday tables.
int _weekdayIndex(DateTime d) => d.weekday % 7;

/// Returns the full Thai month name (มกราคม … ธันวาคม), or "" if [month] is out
/// of range (valid range is 1..12).
String monthTh(int month) {
  if (month < 1 || month > 12) return '';
  return _thaiMonths[month];
}

/// Returns the abbreviated Thai month name (ม.ค. … ธ.ค.), or "" if [month] is
/// out of range (valid range is 1..12).
String monthAbbrTh(int month) {
  if (month < 1 || month > 12) return '';
  return _thaiMonthsAbbr[month];
}

/// Returns the full Thai weekday name with the "วัน" prefix for [d]
/// (วันอาทิตย์ … วันเสาร์). Uses [DateTime.weekday] (Monday=1 .. Sunday=7).
String weekdayTh(DateTime d) => 'วัน${_thaiWeekdays[_weekdayIndex(d)]}';

/// Returns the abbreviated Thai weekday name for [d] (อา. จ. อ. พ. พฤ. ศ. ส.).
String weekdayAbbrTh(DateTime d) => _thaiWeekdaysAbbr[_weekdayIndex(d)];

/// Returns the Buddhist-Era year of [d] (Gregorian year + 543).
int buddhistYear(DateTime d) => d.year + 543;

/// Formats [d] as a Thai date with the Buddhist-Era year and full month:
/// "5 มิถุนายน 2567".
String formatDate(DateTime d) =>
    '${d.day} ${monthTh(d.month)} ${buddhistYear(d)}';

/// Formats [d] with an abbreviated month: "5 มิ.ย. 2567".
String formatDateAbbr(DateTime d) =>
    '${d.day} ${monthAbbrTh(d.month)} ${buddhistYear(d)}';

/// Formats [d] with the weekday and a "พ.ศ." label:
/// "วันพุธที่ 5 มิถุนายน พ.ศ. 2567".
String formatDateFull(DateTime d) =>
    '${weekdayTh(d)}ที่ ${d.day} ${monthTh(d.month)} พ.ศ. ${buddhistYear(d)}';

class _MonthName {
  _MonthName(this.name, this.month);
  final String name;
  final int month;
}

/// Maps every Thai month name (full and abbreviated) to its month, ordered by
/// descending length so the longest match wins.
final List<_MonthName> _monthNames = () {
  final out = <_MonthName>[];
  for (var i = 1; i <= 12; i++) {
    out.add(_MonthName(_thaiMonths[i], i));
    out.add(_MonthName(_thaiMonthsAbbr[i], i));
  }
  out.sort((a, b) => b.name.length.compareTo(a.name.length));
  return out;
}();

/// Parses a Thai date string back into a [DateTime] (at midnight UTC). It
/// accepts the forms produced by [formatDate], [formatDateAbbr] and
/// [formatDateFull] — e.g. "5 มิถุนายน 2567", "5 มิ.ย. 2567" and
/// "วันพุธที่ 5 มิถุนายน พ.ศ. 2567" — with Arabic or Thai digits. The year is
/// interpreted as a Buddhist-Era year (converted to CE with -543). Throws
/// [ThaiNumException] on invalid input.
DateTime parseDate(String s) {
  final norm = toArabicDigits(s);

  var mon = 0;
  for (final mn in _monthNames) {
    if (norm.contains(mn.name)) {
      mon = mn.month;
      break;
    }
  }
  if (mon == 0) {
    throw ThaiNumException('thainum: no Thai month found', s);
  }

  final nums = _digitGroups(norm);
  if (nums.length < 2) {
    throw ThaiNumException('thainum: need a day and a year', s);
  }
  final day = nums[0];
  final be = nums[nums.length - 1];
  final ce = be - 543;

  final res = DateTime.utc(ce, mon, day);
  // DateTime normalizes out-of-range values; reject anything that shifted.
  if (res.year != ce || res.month != mon || res.day != day) {
    throw ThaiNumException('thainum: invalid date', s);
  }
  return res;
}

/// Returns each run of ASCII digits in [s] as an int.
List<int> _digitGroups(String s) {
  final out = <int>[];
  var i = 0;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c < 0x30 || c > 0x39) {
      i++;
      continue;
    }
    var n = 0;
    while (i < s.length) {
      final cc = s.codeUnitAt(i);
      if (cc < 0x30 || cc > 0x39) break;
      n = n * 10 + (cc - 0x30);
      i++;
    }
    out.add(n);
  }
  return out;
}
