import 'spell.dart';

/// Reads the time of day [t] in the formal 24-hour Thai style (นาฬิกา / นาที):
/// 14:30 -> "สิบสี่นาฬิกาสามสิบนาที", 14:00 -> "สิบสี่นาฬิกา".
String formatTime(DateTime t) {
  var out = '${spell(t.hour)}นาฬิกา';
  final m = t.minute;
  if (m != 0) {
    out += '${spell(m)}นาที';
  }
  return out;
}

/// Reads the time of day [t] in the colloquial Thai 6-hour style
/// (ตี / โมงเช้า / บ่าย / โมงเย็น / ทุ่ม / เที่ยง / เที่ยงคืน). A half hour reads
/// "ครึ่ง"; other minutes read "…นาที".
///
///     08:00 -> 'แปดโมงเช้า'   13:00 -> 'บ่ายโมง'   19:00 -> 'หนึ่งทุ่ม'
///     14:30 -> 'บ่ายสองโมงครึ่ง'
///
/// The morning hours 7–11 use the literal clock-hour reading
/// (`เจ็ดโมงเช้า` … `สิบเอ็ดโมงเช้า`) — the common, unambiguous modern
/// convention — rather than the stricter traditional system that counts the
/// morning from one (`โมงเช้า` = 07:00, `สองโมงเช้า` = 08:00).
String formatClock(DateTime t) {
  final h = t.hour;
  String base;
  if (h == 0) {
    base = 'เที่ยงคืน';
  } else if (h <= 5) {
    base = 'ตี${spell(h)}';
  } else if (h == 6) {
    base = 'หกโมงเช้า';
  } else if (h <= 11) {
    base = '${spell(h)}โมงเช้า';
  } else if (h == 12) {
    base = 'เที่ยง';
  } else if (h == 13) {
    base = 'บ่ายโมง';
  } else if (h <= 15) {
    base = 'บ่าย${spell(h - 12)}โมง';
  } else if (h <= 18) {
    base = '${spell(h - 12)}โมงเย็น';
  } else {
    base = '${spell(h - 18)}ทุ่ม';
  }

  final m = t.minute;
  if (m == 30) {
    return '$baseครึ่ง';
  } else if (m != 0) {
    return '$base${spell(m)}นาที';
  }
  return base;
}

/// Reads a duration as Thai words, using วัน / ชั่วโมง / นาที / วินาที for the
/// non-zero components (sub-second parts are dropped). A zero duration reads
/// "ศูนย์วินาที"; a negative one is prefixed with "ลบ".
///
///     Duration(minutes: 90) -> 'หนึ่งชั่วโมงสามสิบนาที'
///     Duration(seconds: 45) -> 'สี่สิบห้าวินาที'
String formatDuration(Duration d) {
  final neg = d.isNegative;
  if (neg) d = -d;
  var total = d.inSeconds;
  final days = total ~/ 86400;
  total %= 86400;
  final hours = total ~/ 3600;
  total %= 3600;
  final mins = total ~/ 60;
  final secs = total % 60;

  final b = StringBuffer();
  if (days > 0) b.write('${spell(days)}วัน');
  if (hours > 0) b.write('${spell(hours)}ชั่วโมง');
  if (mins > 0) b.write('${spell(mins)}นาที');
  if (secs > 0) b.write('${spell(secs)}วินาที');
  var out = b.toString();
  if (out.isEmpty) out = 'ศูนย์วินาที';
  if (neg) out = 'ลบ$out';
  return out;
}
